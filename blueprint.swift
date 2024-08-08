import Foundation

// MARK: - Structs
public struct BlueprintAdTargetingParams {
    public let localID = UUID()
    public let adTargeting: [String: String]

    public init(
         adTargeting: [String: String]
    ) {
        self.adTargeting = adTargeting
    }
}

public struct BlueprintArticle {
    public let localID = UUID()
    public let id: String
    public let byline: String?
    public let images: [BlueprintImage]
    public let links: BlueprintLinks?
    public let kicker: String?
    public let title: String?
    public let trailText: String?
    public let rating: Int?
    public let commentCount: Int?
    public let publishedDate: Date?
    public let lastUpdatedDate: Date?
    public let mediaType: BlueprintMediaType?
    public let duration: TimeInterval?
    public let profileImage: BlueprintImage?
    public let events: [BlueprintLiveEvent]
    public let paletteLight: BlueprintPalette?
    public let paletteDark: BlueprintPalette?
    public let applePodcastURL: URL?
    public let googlePodcastURL: URL?
    public let spotifyPodcastURL: URL?
    public let videos: [BlueprintVideo]

    // This is an indicator as to whether a live blog is still blogging, or if
    // it's been closed.
    public let isLive: Bool?
    public let pocketCastPodcastURL: URL?
    public let renderedItemProd: BlueprintRenderingPlatformSupport?
    public let renderedItemBeta: BlueprintRenderingPlatformSupport?
    public let showQuotedHeadline: Bool?
    public let webContentUri: URL?
    public let tracking: BlueprintTracking
    public let audio: BlueprintAudio?
    public let podcastSeries: BlueprintPodcastSeries?
    public let adTargetingParams: BlueprintAdTargetingParams

    // Needed on lists and articles whereas collections use the adUnit
    // defined in the fronts response (e.g uk/fronts/home)
    public let adUnit: String?
    public let shouldHideReaderRevenue: Bool
    public let shouldHideAdverts: Bool
    public let shouldHideNav: Bool

    // It is available when the listen-to-article is supported on this article
    public let listenToArticle: BlueprintListenToArticle?

    public init(
         id: String,
         byline: String? = nil,
         images: [BlueprintImage] = [],
         links: BlueprintLinks? = nil,
         kicker: String? = nil,
         title: String? = nil,
         trailText: String? = nil,
         rating: Int? = nil,
         commentCount: Int? = nil,
         publishedDate: Date? = nil,
         lastUpdatedDate: Date? = nil,
         mediaType: BlueprintMediaType? = nil,
         duration: TimeInterval? = nil,
         profileImage: BlueprintImage? = nil,
         events: [BlueprintLiveEvent] = [],
         paletteLight: BlueprintPalette? = nil,
         paletteDark: BlueprintPalette? = nil,
         applePodcastURL: URL? = nil,
         googlePodcastURL: URL? = nil,
         spotifyPodcastURL: URL? = nil,
         videos: [BlueprintVideo] = [],
         isLive: Bool? = nil,
         pocketCastPodcastURL: URL? = nil,
         renderedItemProd: BlueprintRenderingPlatformSupport? = nil,
         renderedItemBeta: BlueprintRenderingPlatformSupport? = nil,
         showQuotedHeadline: Bool? = nil,
         webContentUri: URL? = nil,
         tracking: BlueprintTracking,
         audio: BlueprintAudio? = nil,
         podcastSeries: BlueprintPodcastSeries? = nil,
         adTargetingParams: BlueprintAdTargetingParams,
         adUnit: String? = nil,
         shouldHideReaderRevenue: Bool = false,
         shouldHideAdverts: Bool = false,
         shouldHideNav: Bool = false,
         listenToArticle: BlueprintListenToArticle? = nil
    ) {
        self.id = id
        self.byline = byline
        self.images = images
        self.links = links
        self.kicker = kicker
        self.title = title
        self.trailText = trailText
        self.rating = rating
        self.commentCount = commentCount
        self.publishedDate = publishedDate
        self.lastUpdatedDate = lastUpdatedDate
        self.mediaType = mediaType
        self.duration = duration
        self.profileImage = profileImage
        self.events = events
        self.paletteLight = paletteLight
        self.paletteDark = paletteDark
        self.applePodcastURL = applePodcastURL
        self.googlePodcastURL = googlePodcastURL
        self.spotifyPodcastURL = spotifyPodcastURL
        self.videos = videos
        self.isLive = isLive
        self.pocketCastPodcastURL = pocketCastPodcastURL
        self.renderedItemProd = renderedItemProd
        self.renderedItemBeta = renderedItemBeta
        self.showQuotedHeadline = showQuotedHeadline
        self.webContentUri = webContentUri
        self.tracking = tracking
        self.audio = audio
        self.podcastSeries = podcastSeries
        self.adTargetingParams = adTargetingParams
        self.adUnit = adUnit
        self.shouldHideReaderRevenue = shouldHideReaderRevenue
        self.shouldHideAdverts = shouldHideAdverts
        self.shouldHideNav = shouldHideNav
        self.listenToArticle = listenToArticle
    }
}

public struct BlueprintAudio {
    public let localID = UUID()
    public let id: String
    public let source: String?
    public let durationInSeconds: Int?
    public let uri: URL
    public let adFreeUri: URL
    public let mimeType: String?

    public init(
         id: String,
         source: String? = nil,
         durationInSeconds: Int? = nil,
         uri: URL,
         adFreeUri: URL,
         mimeType: String? = nil
    ) {
        self.id = id
        self.source = source
        self.durationInSeconds = durationInSeconds
        self.uri = uri
        self.adFreeUri = adFreeUri
        self.mimeType = mimeType
    }
}

public struct BlueprintBasicTag {
    public let localID = UUID()
    public let id: String
    public let webTitle: String

    public init(
         id: String,
         webTitle: String
    ) {
        self.id = id
        self.webTitle = webTitle
    }
}

public struct BlueprintBranding {
    public let localID = UUID()
    public let brandingType: String
    public let sponsorName: String
    public let logo: String
    public let sponsorUri: URL
    public let label: String
    public let aboutUri: URL
    public let altLogo: String?

    public init(
         brandingType: String,
         sponsorName: String,
         logo: String,
         sponsorUri: URL,
         label: String,
         aboutUri: URL,
         altLogo: String? = nil
    ) {
        self.brandingType = brandingType
        self.sponsorName = sponsorName
        self.logo = logo
        self.sponsorUri = sponsorUri
        self.label = label
        self.aboutUri = aboutUri
        self.altLogo = altLogo
    }
}

public struct BlueprintCard {
    public let localID = UUID()
    public let type: BlueprintCardType
    public let article: BlueprintArticle

    // Boosted cards show a boosted headline size.
    public let boosted: Bool?

    // Compact cards don't show all the information that non-compact cards do,
    // and tend to appear in a carousel.
    public let compact: Bool?
    public let sublinks: [BlueprintArticle]
    public let htmlFallback: String?

    // Individual cards can be branded and not be part of a branded container.
    // Cards that are branded tend to show the sponsor logo and should be
    // returned with a different palette.
    public let branding: BlueprintBranding?

    // Individual cards can be defined as "premium content". If premium_content
    // is true then it implies the card should be hidden from signed-in users,
    // for example if the card has been paid for by an external sponsor.
    public let premiumContent: Bool?
    public let sublinksPaletteLight: BlueprintPalette?
    public let sublinksPaletteDark: BlueprintPalette?

    // This is the number to be used when the card type is CARD_TYPE_NUMBERED.
    public let cardNumber: Int?

    // This optional field is set if this card type is CARD_TYPE_PODCAST_SERIES.
    // It provides the details on the podcast series.
    public let podcastSeries: BlueprintPodcastSeries?

    // The correspondingTags is to denote which of the tags that a user has
    // selected are applied to a particular content item
    public let correspondingTags: [BlueprintMyGuardianFollow]

    // Mega-boosted cards show a even larger headline size.
    public let megaBoosted: Bool?

    public init(
         type: BlueprintCardType,
         article: BlueprintArticle,
         boosted: Bool? = nil,
         compact: Bool? = nil,
         sublinks: [BlueprintArticle] = [],
         htmlFallback: String? = nil,
         branding: BlueprintBranding? = nil,
         premiumContent: Bool? = nil,
         sublinksPaletteLight: BlueprintPalette? = nil,
         sublinksPaletteDark: BlueprintPalette? = nil,
         cardNumber: Int? = nil,
         podcastSeries: BlueprintPodcastSeries? = nil,
         correspondingTags: [BlueprintMyGuardianFollow] = [],
         megaBoosted: Bool? = nil
    ) {
        self.type = type
        self.article = article
        self.boosted = boosted
        self.compact = compact
        self.sublinks = sublinks
        self.htmlFallback = htmlFallback
        self.branding = branding
        self.premiumContent = premiumContent
        self.sublinksPaletteLight = sublinksPaletteLight
        self.sublinksPaletteDark = sublinksPaletteDark
        self.cardNumber = cardNumber
        self.podcastSeries = podcastSeries
        self.correspondingTags = correspondingTags
        self.megaBoosted = megaBoosted
    }
}

public struct BlueprintCollection {
    public let localID = UUID()
    public let id: String

    // A palette at the collection level is currently mapped from MAPI's
    // "navigation style". It's specified when the look and feel of an entire
    // container should be changed, for example when a container is "branded"
    // because the content has been paid for.
    public let paletteLight: BlueprintPalette?
    public let paletteDark: BlueprintPalette?

    // MAPI can technically return a list of empty rows. This might be because
    // MAPI doesn't support the specific content that's included in the
    // collection. In this case it's assumed the client will hide the entire
    // collection from the reader.
    // Another reason for empty rows is that the collection is a titlepiece.
    // In fact, we must keep the rows empty in this case in order not to break
    // old versions of app that were built before titlepiece is introduced.
    public let rows: [BlueprintRow]
    public let title: String?

    // We define branding at the collection level because certain containers
    // require a different look and feel, for example content published by
    // Guardian Labs.
    public let branding: BlueprintBranding?

    // A container can be defined as "premium". Currently this is just for the
    // Crosswords container for which only premium users are allowed to access
    // (although it is visible to all users). Note that the Crosswords
    // container is not curated by Editorial in the fronts tool but instead
    // created on the fly by MAPI.
    public let premiumContent: Bool?
    public let followUp: BlueprintFollowUp?

    // This tells the app whether or not to render a "show/hide" button at the
    // top right of the container. For now, this is only used for thrashers,
    // which should not be hideable by the user.
    public let hideable: Bool
    public let myguardianFollow: BlueprintMyGuardianFollow?

    // For some design on specific types of collections, we want to show
    // an image and a description in the collection header.  This field is
    // used for award text if the collection design is
    // COLLECTION_DESIGN_TITLEPIECE.
    public let description: String?
    public let image: BlueprintImage?

    // This tells the app which design to use to render the collection
    public let design: BlueprintCollectionDesign?

    // When this attribute is true, the vertical spacing is removed from
    // the collection.
    public let compactPadding: Bool?

    // The property gives the ID of the collection to be used in
    // the tracking data.
    public let trackingID: String?

    public init(
         id: String,
         paletteLight: BlueprintPalette? = nil,
         paletteDark: BlueprintPalette? = nil,
         rows: [BlueprintRow] = [],
         title: String? = nil,
         branding: BlueprintBranding? = nil,
         premiumContent: Bool? = nil,
         followUp: BlueprintFollowUp? = nil,
         hideable: Bool = false,
         myguardianFollow: BlueprintMyGuardianFollow? = nil,
         description: String? = nil,
         image: BlueprintImage? = nil,
         design: BlueprintCollectionDesign? = nil,
         compactPadding: Bool? = nil,
         trackingID: String? = nil
    ) {
        self.id = id
        self.paletteLight = paletteLight
        self.paletteDark = paletteDark
        self.rows = rows
        self.title = title
        self.branding = branding
        self.premiumContent = premiumContent
        self.followUp = followUp
        self.hideable = hideable
        self.myguardianFollow = myguardianFollow
        self.description = description
        self.image = image
        self.design = design
        self.compactPadding = compactPadding
        self.trackingID = trackingID
    }
}

public struct BlueprintColumn {
    public let localID = UUID()

    // By default, if there are multiple cards in the cards array then it's
    // expected the client will display these as stacked vertical elements.
    public let cards: [BlueprintCard]
    public let paletteLight: BlueprintPalette?
    public let paletteDark: BlueprintPalette?
    public let preferredWidth: Int

    public init(
         cards: [BlueprintCard] = [],
         paletteLight: BlueprintPalette? = nil,
         paletteDark: BlueprintPalette? = nil,
         preferredWidth: Int
    ) {
        self.cards = cards
        self.paletteLight = paletteLight
        self.paletteDark = paletteDark
        self.preferredWidth = preferredWidth
    }
}

public struct BlueprintFollowUp {
    public let localID = UUID()
    public let type: BlueprintFollowUpType
    public let uri: URL

    // At the time of creation MAPI couldn't support blueprint versions of the
    // follow-on link so this field was marked as optional. As part of the
    // migration work, MAPI will eventually support blueprint endpoints for all
    // follow on links.
    public let blueprintUri: URL?

    public init(
         type: BlueprintFollowUpType,
         uri: URL,
         blueprintUri: URL? = nil
    ) {
        self.type = type
        self.uri = uri
        self.blueprintUri = blueprintUri
    }
}

public struct BlueprintImage {
    public let localID = UUID()
    public let altText: String?
    public let caption: String?
    public let credit: String?
    public let height: Int?
    public let urlTemplate: String
    public let width: Int?

    public init(
         altText: String? = nil,
         caption: String? = nil,
         credit: String? = nil,
         height: Int? = nil,
         urlTemplate: String,
         width: Int? = nil
    ) {
        self.altText = altText
        self.caption = caption
        self.credit = credit
        self.height = height
        self.urlTemplate = urlTemplate
        self.width = width
    }
}

public struct BlueprintLayoutAgnosticCollection {
    public let localID = UUID()
    public let id: String

    // A palette at the collection level is currently mapped from MAPI's
    // "navigation style". It's specified when the look and feel of an entire
    // container should be changed, for example when a container is "branded"
    // because the content has been paid for.
    public let paletteLight: BlueprintPalette?
    public let paletteDark: BlueprintPalette?

    // Here we return a list of cards instead of rows. This means that
    // the client will need to decide how to layout the cards.
    public let cards: [BlueprintCard]
    public let title: String?
    public let followUp: BlueprintFollowUp?

    public init(
         id: String,
         paletteLight: BlueprintPalette? = nil,
         paletteDark: BlueprintPalette? = nil,
         cards: [BlueprintCard] = [],
         title: String? = nil,
         followUp: BlueprintFollowUp? = nil
    ) {
        self.id = id
        self.paletteLight = paletteLight
        self.paletteDark = paletteDark
        self.cards = cards
        self.title = title
        self.followUp = followUp
    }
}

public struct BlueprintLinks {
    public let localID = UUID()
    public let relatedUri: URL
    public let shortURL: URL
    public let uri: URL
    public let webUri: URL

    public init(
         relatedUri: URL,
         shortURL: URL,
         uri: URL,
         webUri: URL
    ) {
        self.relatedUri = relatedUri
        self.shortURL = shortURL
        self.uri = uri
        self.webUri = webUri
    }
}

public struct BlueprintList {
    public let localID = UUID()
    public let title: String

    // The native app will call this URL when a user has scrolled to the bottom
    // of the list and wants to load more content.
    public let nextPageURL: URL?
    public let paletteLight: BlueprintPalette?
    public let paletteDark: BlueprintPalette?
    public let rows: [BlueprintRow]
    public let branding: BlueprintBranding?
    public let topics: [BlueprintTopic]
    public let previousPageURL: URL?
    public let tracking: BlueprintTracking
    public let adverts: [Int]
    public let myGuardianFollow: BlueprintMyGuardianFollow?
    public let id: String

    // This is only neded for tracking, but keeping out of the tracking
    // message incase that changes
    public let webUri: URL?
    public let adTargetingParams: BlueprintAdTargetingParams

    // Needed on lists and articles. Collections use the adUnit defined
    // in the fronts response (e.g uk/fronts/home)
    public let adUnit: String

    public init(
         title: String,
         nextPageURL: URL? = nil,
         paletteLight: BlueprintPalette? = nil,
         paletteDark: BlueprintPalette? = nil,
         rows: [BlueprintRow] = [],
         branding: BlueprintBranding? = nil,
         topics: [BlueprintTopic] = [],
         previousPageURL: URL? = nil,
         tracking: BlueprintTracking,
         adverts: [Int] = [],
         myGuardianFollow: BlueprintMyGuardianFollow? = nil,
         id: String,
         webUri: URL? = nil,
         adTargetingParams: BlueprintAdTargetingParams,
         adUnit: String
    ) {
        self.title = title
        self.nextPageURL = nextPageURL
        self.paletteLight = paletteLight
        self.paletteDark = paletteDark
        self.rows = rows
        self.branding = branding
        self.topics = topics
        self.previousPageURL = previousPageURL
        self.tracking = tracking
        self.adverts = adverts
        self.myGuardianFollow = myGuardianFollow
        self.id = id
        self.webUri = webUri
        self.adTargetingParams = adTargetingParams
        self.adUnit = adUnit
    }
}

public struct BlueprintListenToArticle {
    public let localID = UUID()
    public let audioUri: URL
    public let durationInSeconds: Int

    public init(
         audioUri: URL,
         durationInSeconds: Int
    ) {
        self.audioUri = audioUri
        self.durationInSeconds = durationInSeconds
    }
}

public struct BlueprintLiveEvent {
    public let localID = UUID()
    public let id: String
    public let title: String
    public let body: String
    public let publishedDate: Date?
    public let lastUpdatedDate: Date?

    public init(
         id: String,
         title: String,
         body: String,
         publishedDate: Date? = nil,
         lastUpdatedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.publishedDate = publishedDate
        self.lastUpdatedDate = lastUpdatedDate
    }
}

public struct BlueprintMyGuardianFollow {
    public let localID = UUID()
    public let id: String
    public let webTitle: String
    public let type: BlueprintFollowType

    public init(
         id: String,
         webTitle: String,
         type: BlueprintFollowType
    ) {
        self.id = id
        self.webTitle = webTitle
        self.type = type
    }
}

public struct BlueprintPalette {
    public let localID = UUID()
    public let accentColour: String
    public let background: String
    public let commentCount: String
    public let elementBackground: String
    public let headline: String
    public let immersiveKicker: String
    public let main: String
    public let mediaBackground: String
    public let mediaIcon: String
    public let metaText: String
    public let pill: String
    public let pillar: String
    public let secondary: String
    public let shadow: String
    public let topBorder: String
    public let kickerText: String

    public init(
         accentColour: String,
         background: String,
         commentCount: String,
         elementBackground: String,
         headline: String,
         immersiveKicker: String,
         main: String,
         mediaBackground: String,
         mediaIcon: String,
         metaText: String,
         pill: String,
         pillar: String,
         secondary: String,
         shadow: String,
         topBorder: String,
         kickerText: String
    ) {
        self.accentColour = accentColour
        self.background = background
        self.commentCount = commentCount
        self.elementBackground = elementBackground
        self.headline = headline
        self.immersiveKicker = immersiveKicker
        self.main = main
        self.mediaBackground = mediaBackground
        self.mediaIcon = mediaIcon
        self.metaText = metaText
        self.pill = pill
        self.pillar = pillar
        self.secondary = secondary
        self.shadow = shadow
        self.topBorder = topBorder
        self.kickerText = kickerText
    }
}

public struct BlueprintPermutive {
    public let localID = UUID()
    public let id: String
    public let type: String
    public let title: String?
    public let section: String?
    public let authors: [String]
    public let keywords: [String]
    public let publishedAt: Date?
    public let series: String?

    public init(
         id: String,
         type: String,
         title: String? = nil,
         section: String? = nil,
         authors: [String] = [],
         keywords: [String] = [],
         publishedAt: Date? = nil,
         series: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.section = section
        self.authors = authors
        self.keywords = keywords
        self.publishedAt = publishedAt
        self.series = series
    }
}

public struct BlueprintPodcastSeries {
    public let localID = UUID()
    public let id: String
    public let title: String
    public let url: URL
    public let followUp: BlueprintFollowUp?
    public let image: BlueprintImage?
    public let description: String?

    public init(
         id: String,
         title: String,
         url: URL,
         followUp: BlueprintFollowUp? = nil,
         image: BlueprintImage? = nil,
         description: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.followUp = followUp
        self.image = image
        self.description = description
    }
}

public struct BlueprintRenderingPlatformSupport {
    public let localID = UUID()
    public let minBridgetVersion: String
    public let uri: URL

    public init(
         minBridgetVersion: String,
         uri: URL
    ) {
        self.minBridgetVersion = minBridgetVersion
        self.uri = uri
    }
}

public struct BlueprintRow {
    public let localID = UUID()
    public let columns: [BlueprintColumn]
    public let paletteLight: BlueprintPalette?
    public let paletteDark: BlueprintPalette?

    // Tablet devices support a 4 column display, whereas mobile devices
    // support a 2 column display. If a mobile device receives a row with a
    // preferred number of columns greater than 2, the additional columns are
    // "wrapped" onto an extra row (a bit like CSS flex-wrap).
    public let preferredNumberOfColumns: Int
    public let thrasher: BlueprintThrasher?
    public let type: BlueprintRowType
    public let title: String?

    // When this attribute is true, the spacing in between cards in the row is
    // reduced.
    public let tightenSpacing: Bool?

    public init(
         columns: [BlueprintColumn] = [],
         paletteLight: BlueprintPalette? = nil,
         paletteDark: BlueprintPalette? = nil,
         preferredNumberOfColumns: Int,
         thrasher: BlueprintThrasher? = nil,
         type: BlueprintRowType,
         title: String? = nil,
         tightenSpacing: Bool? = nil
    ) {
        self.columns = columns
        self.paletteLight = paletteLight
        self.paletteDark = paletteDark
        self.preferredNumberOfColumns = preferredNumberOfColumns
        self.thrasher = thrasher
        self.type = type
        self.title = title
        self.tightenSpacing = tightenSpacing
    }
}

public struct BlueprintThrasher {
    public let localID = UUID()
    public let uri: URL

    public init(
         uri: URL
    ) {
        self.uri = uri
    }
}

public struct BlueprintTopic {
    public let localID = UUID()
    public let type: String
    public let name: String
    public let displayName: String

    public init(
         type: String,
         name: String,
         displayName: String
    ) {
        self.type = type
        self.name = name
        self.displayName = displayName
    }
}

public struct BlueprintTracking {
    public let localID = UUID()
    public let permutive: BlueprintPermutive

    // For some lists and articles we return nielsen tracking data
    // depending on the section they belong to
    public let nielsenSection: String?
    public let commissioningDesks: [BlueprintBasicTag]

    public init(
         permutive: BlueprintPermutive,
         nielsenSection: String? = nil,
         commissioningDesks: [BlueprintBasicTag] = []
    ) {
        self.permutive = permutive
        self.nielsenSection = nielsenSection
        self.commissioningDesks = commissioningDesks
    }
}

public struct BlueprintVideo {
    public let localID = UUID()
    public let altText: String?
    public let caption: String?
    public let credit: String?
    public let height: Int?
    public let orientation: String?
    public let url: URL
    public let width: Int?
    public let youtubeID: String?
    public let durationInSeconds: Int?
    public let posterImage: BlueprintImage?

    public init(
         altText: String? = nil,
         caption: String? = nil,
         credit: String? = nil,
         height: Int? = nil,
         orientation: String? = nil,
         url: URL,
         width: Int? = nil,
         youtubeID: String? = nil,
         durationInSeconds: Int? = nil,
         posterImage: BlueprintImage? = nil
    ) {
        self.altText = altText
        self.caption = caption
        self.credit = credit
        self.height = height
        self.orientation = orientation
        self.url = url
        self.width = width
        self.youtubeID = youtubeID
        self.durationInSeconds = durationInSeconds
        self.posterImage = posterImage
    }
}

// MARK: - Enums
extension BlueprintCard {
    public enum BlueprintCardType: Int {
        case unspecified = 0
        case article = 1
        case podcast = 2
        case video = 3
        case crossword = 4
        case display = 5
        case numbered = 6
        case empty = 7
        case webContent = 8
        case podcastSeries = 9
        case highlight = 10
    }
}

extension BlueprintCollection {
    public enum BlueprintCollectionDesign: Int {
        case unspecified = 0
        case regular = 1
        case podcast = 2
        case titlepiece = 3
    }
}

extension BlueprintMyGuardianFollow {
    public enum BlueprintFollowType: Int {
        case unspecified = 0
        case contributor = 1
        case keyword = 2
        case series = 3
        case section = 4
        case newspaperBookSection = 5
        case newspaperBook = 6
        case blog = 7
        case tone = 8
        case publication = 9
        case tracking = 10
        case paidContent = 11
        case campaign = 12
        case type = 13
    }
}

extension BlueprintFollowUp {
    public enum BlueprintFollowUpType: Int {
        case unspecified = 0
        case list = 1
        case front = 2
        case inapp = 3
    }
}

public enum BlueprintMediaType: Int {
    case unspecified = 0
    case video = 1
    case audio = 2
    case image = 3
}

extension BlueprintRow {
    public enum BlueprintRowType: Int {
        case unspecified = 0
        case layout = 1
        case carousel = 2
        case webContent = 3
    }
}

