import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI

/// The Phantomgram accent, taken from the eyes of the logo.
let phantomAccentColor = UIColor(rgb: 0xff5c93)

/// The top of the Phantomgram settings: the logo, the name, the versions and the ghost mode status.
final class PhantomSettingsHeaderItem: ListViewItem, ItemListItem {
    let theme: PresentationTheme
    let title: String
    let subtitle: String
    let status: String
    let isStatusActive: Bool
    let sectionId: ItemListSectionId

    init(theme: PresentationTheme, title: String, subtitle: String, status: String, isStatusActive: Bool, sectionId: ItemListSectionId) {
        self.theme = theme
        self.title = title
        self.subtitle = subtitle
        self.status = status
        self.isStatusActive = isStatusActive
        self.sectionId = sectionId
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, neighbors: ListViewItemNeighbors, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = PhantomSettingsHeaderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topFacet: neighbors.previous?.base(ItemListNeighborFacet.self), bottomFacet: neighbors.next?.base(ItemListNeighborFacet.self)))

            node.contentSize = layout.contentSize
            node.insets = layout.insets

            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, neighbors: ListViewItemNeighbors, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? PhantomSettingsHeaderItemNode else {
                assertionFailure()
                return
            }

            let makeLayout = nodeValue.asyncLayout()

            async {
                let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topFacet: neighbors.previous?.base(ItemListNeighborFacet.self), bottomFacet: neighbors.next?.base(ItemListNeighborFacet.self)))
                Queue.mainQueue().async {
                    completion(layout, { _ in
                        apply()
                    })
                }
            }
        }
    }
}

private let phantomHeaderTitleFont = Font.bold(24.0)
private let phantomHeaderSubtitleFont = Font.regular(14.0)
private let phantomHeaderStatusFont = Font.semibold(13.0)
private let phantomHeaderLogoSize = CGSize(width: 88.0, height: 88.0)
private let phantomHeaderStatusHeight: CGFloat = 26.0

final class PhantomSettingsHeaderItemNode: ListViewItemNode {
    private let logoContainerNode: ASDisplayNode
    private let glowLayer: CALayer
    private let logoNode: ASImageNode
    private let eyesNode: ASImageNode
    private let titleNode: TextNode
    private let subtitleNode: TextNode
    private let statusBackgroundNode: ASImageNode
    private let statusNode: TextNode

    private var item: PhantomSettingsHeaderItem?
    private var didAnimateIn = false

    init() {
        self.logoContainerNode = ASDisplayNode()

        self.glowLayer = CALayer()
        self.glowLayer.shadowColor = phantomAccentColor.cgColor
        self.glowLayer.shadowOffset = CGSize()
        self.glowLayer.shadowRadius = 24.0
        self.glowLayer.shadowOpacity = 0.35

        self.logoNode = ASImageNode()
        self.logoNode.isLayerBacked = true
        self.logoNode.displaysAsynchronously = false
        self.logoNode.clipsToBounds = true
        self.logoNode.cornerRadius = 20.0
        self.logoNode.image = UIImage(bundleImageName: "Settings/PhantomLogo")

        self.eyesNode = ASImageNode()
        self.eyesNode.isLayerBacked = true
        self.eyesNode.displaysAsynchronously = false
        self.eyesNode.clipsToBounds = true
        self.eyesNode.cornerRadius = 20.0
        self.eyesNode.image = UIImage(bundleImageName: "Settings/PhantomEyesGlow")
        self.eyesNode.alpha = 0.5

        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false

        self.subtitleNode = TextNode()
        self.subtitleNode.isUserInteractionEnabled = false

        self.statusBackgroundNode = ASImageNode()
        self.statusBackgroundNode.isLayerBacked = true
        self.statusBackgroundNode.displaysAsynchronously = false

        self.statusNode = TextNode()
        self.statusNode.isUserInteractionEnabled = false

        super.init(layerBacked: false)

        self.addSubnode(self.logoContainerNode)
        self.logoContainerNode.layer.addSublayer(self.glowLayer)
        self.logoContainerNode.addSubnode(self.logoNode)
        self.logoContainerNode.addSubnode(self.eyesNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.subtitleNode)
        self.addSubnode(self.statusBackgroundNode)
        self.addSubnode(self.statusNode)
    }

    func asyncLayout() -> (_ item: PhantomSettingsHeaderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        let makeSubtitleLayout = TextNode.asyncLayout(self.subtitleNode)
        let makeStatusLayout = TextNode.asyncLayout(self.statusNode)
        let currentItem = self.item

        return { [weak self] item, params, neighbors in
            let textWidth = max(1.0, params.width - params.leftInset - params.rightInset - 32.0)

            let statusColor = item.isStatusActive ? phantomAccentColor : item.theme.list.itemSecondaryTextColor

            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.title, font: phantomHeaderTitleFont, textColor: item.theme.list.itemPrimaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets()))
            let (subtitleLayout, subtitleApply) = makeSubtitleLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.subtitle, font: phantomHeaderSubtitleFont, textColor: item.theme.list.freeTextColor), backgroundColor: nil, maximumNumberOfLines: 3, truncationType: .end, constrainedSize: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets()))
            let (statusLayout, statusApply) = makeStatusLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.status, font: phantomHeaderStatusFont, textColor: statusColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: max(1.0, textWidth - 24.0), height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets()))

            var statusBackgroundImage: UIImage?
            if currentItem == nil || currentItem?.isStatusActive != item.isStatusActive || currentItem?.theme !== item.theme {
                statusBackgroundImage = generateStretchableFilledCircleImage(diameter: phantomHeaderStatusHeight, color: statusColor.withAlphaComponent(item.isStatusActive ? 0.16 : 0.12))
            }

            let logoY: CGFloat = 8.0
            let titleY = logoY + phantomHeaderLogoSize.height + 14.0
            let subtitleY = titleY + titleLayout.size.height + 4.0
            let statusY = subtitleY + subtitleLayout.size.height + 12.0
            let height = statusY + phantomHeaderStatusHeight + 8.0

            let contentSize = CGSize(width: params.width, height: height)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)

            return (layout, {
                guard let self else {
                    return
                }
                let statusChanged = self.item != nil && self.item?.isStatusActive != item.isStatusActive
                self.item = item

                let _ = titleApply()
                let _ = subtitleApply()
                let _ = statusApply()
                if let statusBackgroundImage {
                    self.statusBackgroundNode.image = statusBackgroundImage
                }

                let centerX = params.leftInset + floor((params.width - params.leftInset - params.rightInset) / 2.0)
                let logoBounds = CGRect(origin: CGPoint(), size: phantomHeaderLogoSize)
                self.logoContainerNode.bounds = logoBounds
                self.logoContainerNode.position = CGPoint(x: centerX, y: logoY + phantomHeaderLogoSize.height / 2.0)
                self.glowLayer.frame = logoBounds
                self.glowLayer.shadowPath = UIBezierPath(roundedRect: logoBounds.insetBy(dx: 10.0, dy: 10.0), cornerRadius: 16.0).cgPath
                self.logoNode.frame = logoBounds
                self.eyesNode.frame = logoBounds
                self.titleNode.frame = CGRect(origin: CGPoint(x: centerX - floor(titleLayout.size.width / 2.0), y: titleY), size: titleLayout.size)
                self.subtitleNode.frame = CGRect(origin: CGPoint(x: centerX - floor(subtitleLayout.size.width / 2.0), y: subtitleY), size: subtitleLayout.size)

                let statusSize = CGSize(width: statusLayout.size.width + 24.0, height: phantomHeaderStatusHeight)
                let statusFrame = CGRect(origin: CGPoint(x: centerX - floor(statusSize.width / 2.0), y: statusY), size: statusSize)
                self.statusBackgroundNode.frame = statusFrame
                self.statusNode.frame = CGRect(origin: CGPoint(x: statusFrame.minX + 12.0, y: statusFrame.minY + floor((statusSize.height - statusLayout.size.height) / 2.0)), size: statusLayout.size)

                if statusChanged && !UIAccessibility.isReduceMotionEnabled {
                    self.statusBackgroundNode.layer.animateSpring(from: 0.86 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.45)
                    self.statusNode.layer.animateSpring(from: 0.86 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.45)
                    self.statusNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
                }

                self.startAnimationsIfReady()
            })
        }
    }

    override func didEnterHierarchy() {
        super.didEnterHierarchy()

        self.startAnimationsIfReady()
    }

    private func startAnimationsIfReady() {
        guard self.item != nil, self.isInHierarchy, !UIAccessibility.isReduceMotionEnabled else {
            return
        }

        if self.eyesNode.layer.animation(forKey: "phantomPulse") == nil {
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.0 as NSNumber
            pulse.toValue = 1.0 as NSNumber
            pulse.duration = 1.6
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pulse.isRemovedOnCompletion = false
            self.eyesNode.layer.add(pulse, forKey: "phantomPulse")

            let glow = CABasicAnimation(keyPath: "shadowOpacity")
            glow.fromValue = 0.15 as NSNumber
            glow.toValue = 0.55 as NSNumber
            glow.duration = 1.6
            glow.autoreverses = true
            glow.repeatCount = .infinity
            glow.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            glow.isRemovedOnCompletion = false
            self.glowLayer.add(glow, forKey: "phantomPulse")
        }

        if !self.didAnimateIn {
            self.didAnimateIn = true

            self.logoContainerNode.layer.animateSpring(from: 0.85 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.6, damping: 70.0)
            self.logoContainerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)

            let followers: [CALayer] = [self.titleNode.layer, self.subtitleNode.layer, self.statusBackgroundNode.layer, self.statusNode.layer]
            for (index, layer) in followers.enumerated() {
                let delay = 0.08 + 0.05 * Double(min(index, 2))
                layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3, delay: delay)
                layer.animatePosition(from: CGPoint(x: 0.0, y: 12.0), to: CGPoint(), duration: 0.5, delay: delay, timingFunction: kCAMediaTimingFunctionSpring, additive: true)
            }
        }
    }

    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}
