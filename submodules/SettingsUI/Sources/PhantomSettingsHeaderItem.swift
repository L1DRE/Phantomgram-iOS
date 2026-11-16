import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI

/// The top of the Phantomgram settings: the logo, the name and the versions.
final class PhantomSettingsHeaderItem: ListViewItem, ItemListItem {
    let theme: PresentationTheme
    let title: String
    let subtitle: String
    let sectionId: ItemListSectionId

    init(theme: PresentationTheme, title: String, subtitle: String, sectionId: ItemListSectionId) {
        self.theme = theme
        self.title = title
        self.subtitle = subtitle
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
private let phantomHeaderLogoSize = CGSize(width: 88.0, height: 88.0)

final class PhantomSettingsHeaderItemNode: ListViewItemNode {
    private let logoNode: ASImageNode
    private let titleNode: TextNode
    private let subtitleNode: TextNode

    private var item: PhantomSettingsHeaderItem?

    init() {
        self.logoNode = ASImageNode()
        self.logoNode.isLayerBacked = true
        self.logoNode.displaysAsynchronously = false
        self.logoNode.clipsToBounds = true
        self.logoNode.cornerRadius = 20.0
        self.logoNode.image = UIImage(bundleImageName: "Settings/PhantomLogo")

        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false

        self.subtitleNode = TextNode()
        self.subtitleNode.isUserInteractionEnabled = false

        super.init(layerBacked: false)

        self.addSubnode(self.logoNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.subtitleNode)
    }

    func asyncLayout() -> (_ item: PhantomSettingsHeaderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        let makeSubtitleLayout = TextNode.asyncLayout(self.subtitleNode)

        return { [weak self] item, params, neighbors in
            let textWidth = max(1.0, params.width - params.leftInset - params.rightInset - 32.0)

            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.title, font: phantomHeaderTitleFont, textColor: item.theme.list.itemPrimaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets()))
            let (subtitleLayout, subtitleApply) = makeSubtitleLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.subtitle, font: phantomHeaderSubtitleFont, textColor: item.theme.list.freeTextColor), backgroundColor: nil, maximumNumberOfLines: 3, truncationType: .end, constrainedSize: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets()))

            let logoY: CGFloat = 4.0
            let titleY = logoY + phantomHeaderLogoSize.height + 12.0
            let subtitleY = titleY + titleLayout.size.height + 4.0
            let height = subtitleY + subtitleLayout.size.height + 12.0

            let contentSize = CGSize(width: params.width, height: height)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)

            return (layout, {
                guard let self else {
                    return
                }
                self.item = item

                let _ = titleApply()
                let _ = subtitleApply()

                let centerX = params.leftInset + floor((params.width - params.leftInset - params.rightInset) / 2.0)
                self.logoNode.frame = CGRect(origin: CGPoint(x: centerX - floor(phantomHeaderLogoSize.width / 2.0), y: logoY), size: phantomHeaderLogoSize)
                self.titleNode.frame = CGRect(origin: CGPoint(x: centerX - floor(titleLayout.size.width / 2.0), y: titleY), size: titleLayout.size)
                self.subtitleNode.frame = CGRect(origin: CGPoint(x: centerX - floor(subtitleLayout.size.width / 2.0), y: subtitleY), size: subtitleLayout.size)
            })
        }
    }

    override func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }

    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}
