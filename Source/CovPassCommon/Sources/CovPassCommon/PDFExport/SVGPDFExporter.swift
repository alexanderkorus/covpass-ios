//
//  SVGPDFExporter.swift
//
//
//  © Copyright IBM Deutschland GmbH 2021
//  SPDX-License-Identifier: Apache-2.0
//

import PDFKit
import UIKit
import WebKit

/// PDF Exporter for SVG templates
public final class SVGPDFExporter: NSObject, WKNavigationDelegate, SVGPDFExportProtocol {

    public enum ExportError: Error {
        case invalidTemplate
    }

    /// A web view that does not allow Javascript execution.
    private lazy var webView: WKWebView = {
        // JS is disabled as it's not used/required in our SVGs
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = false
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = false
        }
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }()

    /// Date formated as `yyyy-MM-dd`.
    private lazy var dateFormatter = DateUtils.isoDateFormatter

    private var exportHandler: ExportHandler?

    // MARK: - SVGPDFExportProtocol

    public func fill(template: Template, with token: ExtendedCBORWebToken) throws -> SVGData? {
        let certificate = token.vaccinationCertificate.hcert.dgc
        guard
            let data = certificate.template?.data,
            var svg = String(data: data, encoding: .utf8)
        else {
            assertionFailure()
            return nil
        }

        // Common fields
        svg = svg.replacingOccurrences(of: "$nam", with: certificate.nam.fullName)
        svg = svg.replacingOccurrences(of: "$dob", with: certificate.dobString ?? .placeholder)
        svg = svg.replacingOccurrences(of: "$ci", with: certificate.uvci.stripUVCIPrefix())

        // QR code
        let qr = token.vaccinationQRCodeData.generateQRCode(size: CGSize(width: 1000, height: 1000))
        svg = svg.replacingOccurrences(of: "$qr", with: qr?.pngData()?.base64EncodedString() ?? .placeholder)

        switch template.type {
        case .recovery:
            guard let recovery = certificate.latestRecovery else {
                throw ExportError.invalidTemplate
            }
            // disease of agent targeted
            svg = svg.replacingOccurrences(of: "$tg", with: recovery.tgDisplayName)
            // date of first positive test result
            svg = svg.replacingOccurrences(of: "$fr", with: dateFormatter.string(from: recovery.fr))
            // valid from
            svg = svg.replacingOccurrences(of: "$df", with: dateFormatter.string(from: recovery.df))
            // valid until
            svg = svg.replacingOccurrences(of: "$du", with: dateFormatter.string(from: recovery.du))
            // country
            svg = svg.replacingOccurrences(of: "$co", with: recovery.co)
            // certificate issue
            svg = svg.replacingOccurrences(of: "$is", with: recovery.is)
        case.test:
            guard let test = certificate.latestTest else {
                throw ExportError.invalidTemplate
            }
            // disease of agent targeted
            svg = svg.replacingOccurrences(of: "$tg", with: test.tgDisplayName)
            // test type
            svg = svg.replacingOccurrences(of: "$tt", with: test.ttDisplayName)
            // test name
            svg = svg.replacingOccurrences(of: "$nm", with: test.nm ?? .placeholder)
            // test manufacturer
            svg = svg.replacingOccurrences(of: "$ma", with: test.maDisplayName ?? .placeholder)
            // sample collection
            svg = svg.replacingOccurrences(of: "$sc", with: dateFormatter.string(from: test.sc))
            // test result
            svg = svg.replacingOccurrences(of: "$tr", with: test.trDisplayName)
            // testing center
            svg = svg.replacingOccurrences(of: "$tc", with: test.tc)
            // country
            svg = svg.replacingOccurrences(of: "$co", with: test.co)
            // certificate issue
            svg = svg.replacingOccurrences(of: "$is", with: test.is)
        case .vaccination:
            guard let vaccination = certificate.latestVaccination else {
                throw ExportError.invalidTemplate
            }
            // disease of agent targeted
            svg = svg.replacingOccurrences(of: "$tg", with: vaccination.tgDisplayName)
            // vaccine
            svg = svg.replacingOccurrences(of: "$vp", with: vaccination.vpDisplayName)
            // vaccine product name
            svg = svg.replacingOccurrences(of: "$mp", with: vaccination.mp)
            // marketing authorization
            svg = svg.replacingOccurrences(of: "$ma", with: vaccination.maDisplayName)
            // vaccination x of y - number format is not localized!
            svg = svg.replacingOccurrences(of: "$dn", with: vaccination.dn.description)
            svg = svg.replacingOccurrences(of: "$sd", with: vaccination.sd.description)
            // date vaccination
            svg = svg.replacingOccurrences(of: "$dt", with: dateFormatter.string(from: vaccination.dt))
            // country
            svg = svg.replacingOccurrences(of: "$co", with: vaccination.coDisplayName)
            // certificate issue
            svg = svg.replacingOccurrences(of: "$is", with: vaccination.is)
        }

        #if DEBUG
        let regex = try! NSRegularExpression(pattern: "\\>\\$\\w+\\<")
        let range = NSRange(location: 0, length: svg.utf16.count)
        if let match = regex.firstMatch(in: svg, options: [], range: range) {
            let nsString = svg as NSString
            let matchString = nsString.substring(with: match.range) as String
            assertionFailure("missed one placeholder: \(matchString)")
        }
        #endif

        return svg.data(using: .utf8)
    }

    public func export(_ data: SVGData, completion: ExportHandler?) {
        guard let string = String(data: data, encoding: .utf8) else {
            preconditionFailure("Expected a String")
        }
        webView.navigationDelegate = self
        // completion is called after web view has loaded
        exportHandler = completion

        // temporarily add the webview to the general view hierarchy
        webView.frame = UIApplication.shared.keyWindow?.bounds ?? .zero
        // the webview has to be visible – nobody said how much…
        // this HACK prevents the screen to 'blink' during page rendering and PDF export
        webView.alpha = 0.01
        UIApplication.shared.keyWindow?.addSubview(webView)

        webView.loadHTMLString(string, baseURL: nil)
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView == self.webView else { return }

        defer {
            webView.removeFromSuperview()
        }
        do {
            let pdf = try webView.exportAsPDF()
            exportHandler?(pdf)
        } catch {
            assertionFailure("Export error: \(error)")
            exportHandler?(nil)
        }
    }
}

// MARK: – Helper Extensions

public extension ExtendedCBORWebToken {
    /// Checks if a certificate in the given token can be exported to PDF
    ///
    /// If multiple certificates are present the priotization is as follows (most to least important):
    /// 1. vaccination
    /// 2. test
    /// 3. recovery
    var canExportToPDF: Bool {
        vaccinationCertificate.hcert.dgc.template != nil
    }
}

extension DigitalGreenCertificate {
    /// Checks if the given certificate can be exported
    var canExportToPDF: Bool {
        template != nil
    }

    var latestRecovery: Recovery? {
        r?.sorted(by: { $0.df > $1.df }).first
    }

    var latestTest: Test? {
        t?.sorted(by: { $0.sc > $1.sc }).first
    }

    var latestVaccination: Vaccination? {
        v?.sorted(by: { $0.dt > $1.dt }).first
    }
}

private extension String {
    static let placeholder = "–"
}
