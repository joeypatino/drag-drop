import XCTest
import SwiftUI
import UIKit

/// Evidence, not behaviour: the pickup delay can only be found for a view
/// inside SwiftUI's scrolling containers if UIKit puts a scroll view above it.
/// This file pins that assumption, so an SDK that changes it fails here
/// rather than as a drag that swallows scrolls.
@MainActor
final class SwiftUIScrollAncestryTests: XCTestCase {

    private struct Probe: UIViewRepresentable {
        let view: UIView
        func makeUIView(context: Context) -> UIView { view }
        func updateUIView(_ uiView: UIView, context: Context) {}
    }

    private func ancestors<Content: View>(of probe: UIView, mountedIn content: Content) -> [UIView] {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.rootViewController = UIHostingController(rootView: content)
        window.isHidden = false
        window.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        XCTAssertNotNil(probe.window, "SwiftUI did not mount the representable")
        return Array(sequence(first: probe, next: \.superview).dropFirst())
    }

    private func names(_ views: [UIView]) -> String {
        views.map { String(describing: type(of: $0)) }.joined(separator: " < ")
    }

    func testAViewInsideAScrollViewHasAUIScrollViewAncestor() {
        let probe = UIView()
        let chain = ancestors(of: probe, mountedIn: ScrollView {
            Probe(view: probe).frame(width: 100, height: 100)
        })
        XCTAssertTrue(chain.contains { $0 is UIScrollView }, names(chain))
    }

    func testAViewInsideAListHasAScrollingAncestor() {
        let probe = UIView()
        let chain = ancestors(of: probe, mountedIn: List {
            Probe(view: probe).frame(width: 100, height: 100)
        })
        XCTAssertTrue(chain.contains { $0 is UIScrollView || $0 is UICollectionViewCell }, names(chain))
    }
}
