/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 *
 * Modified in this local fork.
 */

import Flutter
import UIKit
import YandexMobileAds

@MainActor
final class FlutterNativeAdView: NSObject, FlutterPlatformView {

    private let displaySize: NativeAdDisplaySize
    private let nativeAdView: NativeAdTemplateView
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private let eventRelay: NativeAdEventRelay
    private let nativeAdDelegate: NativeAdDelegateProxy
    private var adLoader: NativeAdLoader?
    private var nativeAd: (any NativeAd)?
    private var requestSequence = 0
    private var isDestroyed = false
    private var isLoadPending = false
    private var pendingAdUnitID = ""

    /// Called with the loaded ad, or with nil when it is released.
    var onAdReady: (((any NativeAd)?) -> Void)?

    /// Called once the view gave up its method and event channels.
    var onDisposed: (() -> Void)?

    init(
        displaySize: NativeAdDisplaySize,
        template: NativeAdTemplate,
        style: NativeAdStyle,
        methodChannel: FlutterMethodChannel,
        eventChannel: FlutterEventChannel
    ) {
        self.displaySize = displaySize
        self.nativeAdView = NativeAdTemplateView(template: template, style: style)
        self.methodChannel = methodChannel
        self.eventChannel = eventChannel
        self.eventRelay = NativeAdEventRelay()
        self.nativeAdDelegate = NativeAdDelegateProxy()
        super.init()
        eventRelay.attach(to: self)
        nativeAdDelegate.owner = self
        eventChannel.setStreamHandler(eventRelay)
        nativeAdView.isHidden = true
    }

    func view() -> UIView {
        nativeAdView
    }

    func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "load":
            guard !isDestroyed else {
                result(FlutterError(code: "disposed", message: "native ad view is destroyed", details: nil))
                return
            }
            guard let requestValues = Self.requestValues(from: call.arguments) else {
                result(FlutterError(code: "args", message: "args must be Map<String, Object?>", details: nil))
                return
            }
            load(requestValues: requestValues)
            result(nil)
        case "cancelLoading":
            cancelLoading()
            result(nil)
        case "destroy":
            destroy()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func handleClick(from ad: any NativeAd) {
        guard !isDestroyed, nativeAd === ad else { return }
        eventRelay.send(name: "onAdClicked")
    }

    func handleImpression(from ad: any NativeAd, impressionData: (any ImpressionData)?) {
        guard !isDestroyed, nativeAd === ad else { return }
        eventRelay.send(name: "onImpression", values: ["impressionData": impressionData?.rawData])
    }

    /// Rebinds an ad that outlived its previous platform view.
    func bindCachedAd(_ ad: any NativeAd) {
        guard !isDestroyed else { return }
        requestSequence &+= 1
        bind(ad: ad, adUnitID: "", cached: true)
    }

    private func load(requestValues: [String: Any?]) {
        requestSequence &+= 1
        let sequence = requestSequence
        let request = requestValues.toAdRequest()
        releaseLoadedAd()
        nativeAdView.isHidden = true

        guard nativeAdView.canRender(in: displaySize) else {
            isLoadPending = false
            sendLayoutFailure(adUnitID: request.adUnitID, required: nil)
            return
        }

        isLoadPending = true
        pendingAdUnitID = request.adUnitID
        let loader = NativeAdLoader()
        adLoader = loader
        loader.loadAd(with: request, options: NativeAdOptions()) { [weak self] loadResult in
            guard let self, !self.isDestroyed, self.requestSequence == sequence else { return }
            switch loadResult {
            case .success(let ad):
                self.bind(ad: ad, adUnitID: request.adUnitID, cached: false)
            case .failure(let error):
                self.isLoadPending = false
                self.sendLoadFailure(error: error, adUnitID: request.adUnitID)
            }
        }
    }

    private func bind(ad: any NativeAd, adUnitID: String, cached: Bool) {
        ad.delegate = nativeAdDelegate
        do {
            try ad.bind(with: nativeAdView)
            let required = nativeAdView.boundContentSize(in: displaySize)
            guard Int(ceil(required.width)) <= displaySize.width,
                  Int(ceil(required.height)) <= displaySize.height else {
                ad.delegate = nil
                nativeAdView.isHidden = true
                isLoadPending = false
                sendLayoutFailure(adUnitID: adUnitID, required: required)
                return
            }
            isLoadPending = false
            nativeAd = ad
            if !cached {
                onAdReady?(ad)
            }
            nativeAdView.isHidden = false
            eventRelay.send(
                name: "onAdLoaded",
                values: ["width": displaySize.width, "height": displaySize.height]
            )
        } catch {
            ad.delegate = nil
            nativeAdView.isHidden = true
            isLoadPending = false
            sendLoadFailure(error: error, adUnitID: adUnitID)
        }
    }

    private func releaseLoadedAd() {
        nativeAd?.delegate = nil
        nativeAd = nil
        onAdReady?(nil)
    }

    private func sendLoadFailure(error: Error, adUnitID: String) {
        eventRelay.send(
            name: "onAdFailedToLoad",
            values: [
                "code": error._code,
                "description": error.localizedDescription,
                "adUnitId": adUnitID,
            ]
        )
    }

    private func sendLayoutFailure(adUnitID: String, required: CGSize?) {
        let requirement: String
        if let required {
            requirement = "\(Int(ceil(required.width)))x\(Int(ceil(required.height)))"
        } else {
            requirement = nativeAdView.minimumContainerDescription
        }
        eventRelay.send(
            name: "onAdFailedToLoad",
            values: [
                "code": -1,
                "description": "native ad container must be at least \(requirement)",
                "adUnitId": adUnitID,
            ]
        )
    }

    private func cancelLoading() {
        guard !isDestroyed else { return }
        requestSequence &+= 1
        isLoadPending = false
        releaseLoadedAd()
        adLoader = nil
        nativeAdView.isHidden = true
        eventRelay.clearPendingEvents()
    }

    private func destroy() {
        guard !isDestroyed else { return }
        isDestroyed = true
        requestSequence &+= 1
        if isLoadPending {
            isLoadPending = false
            eventRelay.send(
                name: "onAdFailedToLoad",
                values: [
                    "code": -3,
                    "description": "native ad view was destroyed while loading",
                    "adUnitId": pendingAdUnitID,
                ]
            )
        }
        releaseLoadedAd()
        adLoader = nil
        nativeAdView.isHidden = true
        nativeAdDelegate.owner = nil
        eventRelay.detach()
        onDisposed?()
        onDisposed = nil
        onAdReady = nil
    }

    private static func requestValues(from arguments: Any?) -> [String: Any?]? {
        if let values = arguments as? [String: Any?] {
            return values
        }
        guard let values = arguments as? [String: Any] else { return nil }
        return values.mapValues { Optional($0) }
    }
}

@MainActor
private final class NativeAdDelegateProxy: NSObject, NativeAdDelegate {

    weak var owner: FlutterNativeAdView?

    func nativeAdDidClick(_ ad: any NativeAd) {
        owner?.handleClick(from: ad)
    }

    func nativeAd(_ ad: any NativeAd, didTrackImpression impressionData: (any ImpressionData)?) {
        owner?.handleImpression(from: ad, impressionData: impressionData)
    }
}

@MainActor
private final class NativeAdEventRelay: NSObject, @preconcurrency FlutterStreamHandler {

    private weak var owner: FlutterNativeAdView?
    private var sink: FlutterEventSink?
    private var pendingEvents: [[String: Any?]] = []

    private let maximumPendingEvents = 32

    func attach(to owner: FlutterNativeAdView) {
        self.owner = owner
    }

    func detach() {
        owner = nil
        sink = nil
        pendingEvents.removeAll()
    }

    func send(name: String, values: [String: Any?] = [:]) {
        guard owner != nil else { return }
        var event = values
        event["name"] = name
        if let sink {
            sink(event)
            return
        }
        if pendingEvents.count == maximumPendingEvents {
            pendingEvents.removeFirst()
        }
        pendingEvents.append(event)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard owner != nil else { return nil }
        sink = events
        let queuedEvents = pendingEvents
        pendingEvents.removeAll()
        queuedEvents.forEach(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        clearPendingEvents()
        return nil
    }

    func clearPendingEvents() {
        pendingEvents.removeAll()
    }
}

enum NativeAdTemplate {
    case compact
    case media

    init?(rawValue: String?) {
        switch rawValue {
        case "compact": self = .compact
        case "media": self = .media
        default: return nil
        }
    }

    var mediaHeight: CGFloat {
        switch self {
        case .compact: 160
        case .media: 180
        }
    }

    var bodyLineCount: Int {
        switch self {
        case .compact: 2
        case .media: 3
        }
    }
}

struct NativeAdDisplaySize {
    let width: Int
    let height: Int

    init(width: Int, height: Int) {
        self.width = max(0, width)
        self.height = max(0, height)
    }
}

struct NativeAdStyle {
    let backgroundColor: UIColor?
    let titleColor: UIColor?
    let bodyColor: UIColor?
    let metadataColor: UIColor?
    let callToActionTextColor: UIColor?
    let callToActionBackgroundColor: UIColor?
    let cornerRadius: CGFloat?
    let contentPadding: CGFloat?

    init(values: [String: Any]) {
        backgroundColor = Self.color(values["backgroundColor"])
        titleColor = Self.color(values["titleColor"])
        bodyColor = Self.color(values["bodyColor"])
        metadataColor = Self.color(values["metadataColor"])
        callToActionTextColor = Self.visibleColor(values["callToActionTextColor"])
        callToActionBackgroundColor = Self.visibleColor(values["callToActionBackgroundColor"])
        cornerRadius = Self.dimension(values["cornerRadius"], maximum: 48)
        contentPadding = Self.dimension(values["contentPadding"], maximum: 64)
    }

    private static func color(_ value: Any?) -> UIColor? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite,
              number.doubleValue.rounded(.towardZero) == number.doubleValue,
              number.doubleValue >= Double(Int32.min),
              number.doubleValue <= Double(UInt32.max) else {
            return nil
        }
        let argb = UInt32(truncatingIfNeeded: number.int64Value)
        return UIColor(
            red: CGFloat((argb >> 16) & 0xff) / 255,
            green: CGFloat((argb >> 8) & 0xff) / 255,
            blue: CGFloat(argb & 0xff) / 255,
            alpha: CGFloat((argb >> 24) & 0xff) / 255
        )
    }

    private static func visibleColor(_ value: Any?) -> UIColor? {
        guard let color = color(value), color.cgColor.alpha >= 0.99 else { return nil }
        return color
    }

    private static func dimension(_ value: Any?, maximum: Double) -> CGFloat? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite,
              number.doubleValue >= 0,
              number.doubleValue <= maximum else {
            return nil
        }
        return CGFloat(number.doubleValue)
    }

    static func readableTextColor(_ requested: UIColor?, on background: UIColor) -> UIColor {
        let fallback: UIColor = relativeLuminance(of: background) > 0.5 ? .black : .white
        guard let requested, contrastRatio(requested, background) >= 4.5 else { return fallback }
        return requested
    }

    private static func contrastRatio(_ first: UIColor, _ second: UIColor) -> CGFloat {
        let lighter = max(relativeLuminance(of: first), relativeLuminance(of: second))
        let darker = min(relativeLuminance(of: first), relativeLuminance(of: second))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(of color: UIColor) -> CGFloat {
        let resolved = color.resolvedColor(with: .current)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return 0 }
        return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
    }

    private static func linearized(_ component: CGFloat) -> CGFloat {
        component <= 0.04045
            ? component / 12.92
            : CGFloat(pow(Double((component + 0.055) / 1.055), 2.4))
    }
}

@MainActor
private final class NativeAdTemplateView: NativeAdView {

    private let title = UILabel()
    private let domain = UILabel()
    private let warning = UILabel()
    private let sponsored = UILabel()
    private let feedback = UIButton(type: .system)
    private let callToAction = UIButton(type: .system)
    private let media: NativeMediaView
    private let icon = UIImageView()
    private let price = UILabel()
    private let body = UILabel()
    private let contentStack: UIStackView
    private let minimumContainerSize: CGSize
    private let bodyLineCount: Int
    private var contentLeading: NSLayoutConstraint!
    private var contentTrailing: NSLayoutConstraint!
    private var contentTop: NSLayoutConstraint!
    private var contentBottom: NSLayoutConstraint!
    private var mediaHeight: NSLayoutConstraint!

    init(template: NativeAdTemplate, style: NativeAdStyle) {
        let contentStack = UIStackView()
        let media = NativeMediaView()
        let padding = style.contentPadding ?? 12
        self.contentStack = contentStack
        self.media = media
        self.minimumContainerSize = CGSize(
            width: NativeAdLayoutSize.minimumMediaWidth + padding * 2,
            height: template.mediaHeight + NativeAdLayoutSize.minimumInteractiveSize * 2
                + NativeAdLayoutSize.metadataLine * NativeAdLayoutSize.metadataLineCount
                + NativeAdLayoutSize.stackSpacing * NativeAdLayoutSize.stackGapCount
                + padding * 2
        )
        self.bodyLineCount = template.bodyLineCount
        super.init(frame: .zero)
        contentLeading = contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
        contentTrailing = contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        contentTop = contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        contentBottom = contentStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        mediaHeight = media.heightAnchor.constraint(equalToConstant: template.mediaHeight)
        configureLayout()
        bindAssets()
        apply(style: style)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func configureLayout() {
        contentStack.axis = .vertical
        contentStack.spacing = NativeAdLayoutSize.stackSpacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([contentLeading, contentTrailing, contentTop, contentBottom])

        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: NativeAdLayoutSize.minimumInteractiveSize).isActive = true
        icon.heightAnchor.constraint(equalToConstant: NativeAdLayoutSize.minimumInteractiveSize).isActive = true
        feedback.widthAnchor.constraint(equalToConstant: NativeAdLayoutSize.minimumInteractiveSize).isActive = true
        feedback.heightAnchor.constraint(equalToConstant: NativeAdLayoutSize.minimumInteractiveSize).isActive = true
        callToAction.heightAnchor.constraint(greaterThanOrEqualToConstant: NativeAdLayoutSize.minimumInteractiveSize).isActive = true
        media.translatesAutoresizingMaskIntoConstraints = false
        mediaHeight.isActive = true

        title.font = .preferredFont(forTextStyle: .headline)
        title.numberOfLines = 2
        domain.font = .preferredFont(forTextStyle: .subheadline)
        domain.numberOfLines = 1
        warning.font = .preferredFont(forTextStyle: .caption2)
        warning.numberOfLines = 0
        sponsored.font = .preferredFont(forTextStyle: .caption1)
        sponsored.numberOfLines = 1
        price.font = .preferredFont(forTextStyle: .caption1)
        price.numberOfLines = 1
        body.font = .preferredFont(forTextStyle: .body)
        body.numberOfLines = bodyLineCount
        callToAction.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        callToAction.contentEdgeInsets = .init(top: 8, left: 12, bottom: 8, right: 12)

        let titleStack = UIStackView(arrangedSubviews: [title, domain, price])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        let header = UIStackView(arrangedSubviews: [icon, titleStack, feedback])
        header.axis = .horizontal
        header.alignment = .top
        header.spacing = 8
        let metadata = UIStackView(arrangedSubviews: [sponsored, warning])
        metadata.axis = .vertical
        metadata.spacing = 2

        contentStack.addArrangedSubview(header)
        contentStack.addArrangedSubview(media)
        contentStack.addArrangedSubview(body)
        contentStack.addArrangedSubview(metadata)
        contentStack.addArrangedSubview(callToAction)
    }

    private func bindAssets() {
        titleLabel = title
        domainLabel = domain
        warningLabel = warning
        sponsoredLabel = sponsored
        feedbackButton = feedback
        callToActionButton = callToAction
        mediaView = media
        priceLabel = price
        bodyLabel = body
        iconImageView = icon
    }

    private func apply(style: NativeAdStyle) {
        backgroundColor = style.backgroundColor ?? .secondarySystemBackground
        title.textColor = style.titleColor ?? .label
        body.textColor = style.bodyColor ?? .label
        domain.textColor = style.metadataColor ?? .secondaryLabel
        price.textColor = style.metadataColor ?? .secondaryLabel
        sponsored.textColor = .secondaryLabel
        warning.textColor = .secondaryLabel
        let callToActionBackground = style.callToActionBackgroundColor ?? .systemBlue
        callToAction.backgroundColor = callToActionBackground
        callToAction.setTitleColor(
            NativeAdStyle.readableTextColor(style.callToActionTextColor, on: callToActionBackground),
            for: .normal
        )
        let radius = style.cornerRadius ?? 12
        layer.cornerRadius = radius
        layer.masksToBounds = true
        callToAction.layer.cornerRadius = min(radius, 10)
        callToAction.clipsToBounds = true
        media.layer.cornerRadius = min(radius, 10)
        media.clipsToBounds = true
        let padding = style.contentPadding ?? 12
        contentLeading.constant = padding
        contentTrailing.constant = -padding
        contentTop.constant = padding
        contentBottom.constant = -padding
    }

    func canRender(in displaySize: NativeAdDisplaySize) -> Bool {
        displaySize.width >= Int(ceil(minimumContainerSize.width))
            && displaySize.height >= Int(ceil(minimumContainerSize.height))
    }

    /// Size the bound content actually needs at the container width.
    func boundContentSize(in displaySize: NativeAdDisplaySize) -> CGSize {
        layoutIfNeeded()
        return systemLayoutSizeFitting(
            CGSize(width: CGFloat(displaySize.width), height: .greatestFiniteMagnitude),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    var minimumContainerDescription: String {
        "\(Int(ceil(minimumContainerSize.width)))x\(Int(ceil(minimumContainerSize.height)))"
    }
}

private enum NativeAdLayoutSize {
    static let minimumMediaWidth: CGFloat = 300
    static let minimumInteractiveSize: CGFloat = 64
    static let stackSpacing: CGFloat = 8
    static let stackGapCount: CGFloat = 5
    static let metadataLine: CGFloat = 20
    static let metadataLineCount: CGFloat = 3
}
