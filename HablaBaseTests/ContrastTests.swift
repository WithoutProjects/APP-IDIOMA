import SwiftUI
import UIKit
import XCTest
@testable import HablaBase

/// Every level tone and teaching colour must keep text readable (WCAG AA, 4.5:1) in light and dark mode.
final class ContrastTests: XCTestCase {
    private let light = UITraitCollection(userInterfaceStyle: .light)
    private let dark = UITraitCollection(userInterfaceStyle: .dark)
    private let white = UIColor.white
    private let lightCard = UIColor.secondarySystemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    private let darkCard = UIColor.secondarySystemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

    func testToneTextReadsOnLightAndDarkBackgrounds() {
        for tone in Tone.levels {
            let main = UIColor(tone.main)
            XCTAssertGreaterThanOrEqual(contrast(main.resolvedColor(with: light), lightCard), 4.5)
            XCTAssertGreaterThanOrEqual(contrast(main.resolvedColor(with: dark), darkCard), 4.5)
        }
    }

    func testWhiteTextReadsOnToneFills() {
        for tone in Tone.levels {
            XCTAssertGreaterThanOrEqual(contrast(UIColor(tone.fill), white), 4.5)
        }
        for fill in [Palette.successFill, Palette.warningFill] {
            XCTAssertGreaterThanOrEqual(contrast(UIColor(fill), white), 4.5)
        }
    }

    func testBrickColoursReadAsTextAndUnderWhiteText() {
        for brick in [Brick.stem, .ending, .time, .rail, .chunk] {
            let color = UIColor(brick.color)
            XCTAssertGreaterThanOrEqual(contrast(color.resolvedColor(with: light), lightCard), 4.5)
            XCTAssertGreaterThanOrEqual(contrast(color.resolvedColor(with: dark), darkCard), 4.5)
            XCTAssertGreaterThanOrEqual(contrast(UIColor(brick.fill), white), 4.5)
        }
    }

    private func contrast(_ a: UIColor, _ b: UIColor) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func linear(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }
}
