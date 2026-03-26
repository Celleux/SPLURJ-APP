import SwiftUI
import PhosphorSwift

struct SplurjIcon: View {
    let phosphor: Image
    let size: CGFloat

    init(_ phosphor: Image, size: CGFloat = 20) {
        self.phosphor = phosphor
        self.size = size
    }

    var body: some View {
        phosphor
            .frame(width: size, height: size)
    }
}

enum PhIcon {
    static var house: Image { Ph.house.duotone }
    static var houseFill: Image { Ph.house.fill }
    static var wallet: Image { Ph.wallet.duotone }
    static var walletFill: Image { Ph.wallet.fill }
    static var gameController: Image { Ph.gameController.duotone }
    static var gameControllerFill: Image { Ph.gameController.fill }
    static var wrench: Image { Ph.wrench.duotone }
    static var wrenchFill: Image { Ph.wrench.fill }
    static var chatCircle: Image { Ph.chatCircle.duotone }
    static var chatCircleFill: Image { Ph.chatCircle.fill }
    static var userCircle: Image { Ph.userCircle.duotone }
    static var userCircleFill: Image { Ph.userCircle.fill }

    static var star: Image { Ph.star.duotone }
    static var starFill: Image { Ph.star.fill }
    static var fire: Image { Ph.fire.duotone }
    static var fireFill: Image { Ph.fire.fill }
    static var trophy: Image { Ph.trophy.duotone }
    static var trophyFill: Image { Ph.trophy.fill }
    static var crown: Image { Ph.crown.duotone }
    static var crownFill: Image { Ph.crown.fill }
    static var lightning: Image { Ph.lightning.duotone }
    static var lightningFill: Image { Ph.lightning.fill }
    static var diamond: Image { Ph.diamond.duotone }
    static var diamondFill: Image { Ph.diamond.fill }
    static var sparkle: Image { Ph.sparkle.duotone }
    static var sparkleFill: Image { Ph.sparkle.fill }
    static var heart: Image { Ph.heart.duotone }
    static var heartFill: Image { Ph.heart.fill }
    static var bell: Image { Ph.bell.duotone }
    static var bellFill: Image { Ph.bell.fill }
    static var bellRinging: Image { Ph.bellRinging.duotone }

    static var chartBar: Image { Ph.chartBar.duotone }
    static var chartBarFill: Image { Ph.chartBar.fill }
    static var chartPie: Image { Ph.chartPie.duotone }
    static var chartPieFill: Image { Ph.chartPie.fill }
    static var trendUp: Image { Ph.trendUp.duotone }
    static var trendDown: Image { Ph.trendDown.duotone }
    static var currencyDollar: Image { Ph.currencyDollar.duotone }
    static var currencyDollarFill: Image { Ph.currencyDollar.fill }
    static var piggyBank: Image { Ph.piggyBank.duotone }
    static var piggyBankFill: Image { Ph.piggyBank.fill }

    static var brain: Image { Ph.brain.duotone }
    static var brainFill: Image { Ph.brain.fill }
    static var wind: Image { Ph.wind.duotone }
    static var timer: Image { Ph.timer.duotone }
    static var timerFill: Image { Ph.timer.fill }
    static var book: Image { Ph.book.duotone }
    static var bookFill: Image { Ph.book.fill }
    static var lightbulb: Image { Ph.lightbulb.duotone }
    static var lightbulbFill: Image { Ph.lightbulb.fill }
    static var shield: Image { Ph.shield.duotone }
    static var shieldFill: Image { Ph.shield.fill }
    static var shieldCheck: Image { Ph.shieldCheck.duotone }
    static var shieldCheckFill: Image { Ph.shieldCheck.fill }
    static var lungs: Image { Ph.wind.duotone }
    static var lungsFill: Image { Ph.wind.fill }
    static var personArmsSpread: Image { Ph.personArmsSpread.duotone }

    static var xCircle: Image { Ph.xCircle.duotone }
    static var xCircleFill: Image { Ph.xCircle.fill }
    static var x: Image { Ph.x.bold }
    static var checkCircle: Image { Ph.checkCircle.duotone }
    static var checkCircleFill: Image { Ph.checkCircle.fill }
    static var check: Image { Ph.check.bold }
    static var caretRight: Image { Ph.caretRight.bold }
    static var caretLeft: Image { Ph.caretLeft.bold }
    static var caretDown: Image { Ph.caretDown.bold }
    static var caretUp: Image { Ph.caretUp.bold }
    static var arrowRight: Image { Ph.arrowRight.bold }
    static var arrowLeft: Image { Ph.arrowLeft.bold }
    static var arrowUp: Image { Ph.arrowUp.bold }
    static var arrowDown: Image { Ph.arrowDown.bold }
    static var arrowUpRight: Image { Ph.arrowUpRight.bold }
    static var arrowDownRight: Image { Ph.arrowDownRight.bold }
    static var arrowClockwise: Image { Ph.arrowClockwise.bold }
    static var arrowsLeftRight: Image { Ph.arrowsLeftRight.duotone }
    static var arrowsDownUp: Image { Ph.arrowsDownUp.duotone }
    static var shareNetwork: Image { Ph.shareNetwork.duotone }
    static var shareFat: Image { Ph.shareFat.duotone }

    static var clock: Image { Ph.clock.duotone }
    static var clockFill: Image { Ph.clock.fill }
    static var calendar: Image { Ph.calendar.duotone }
    static var calendarFill: Image { Ph.calendar.fill }
    static var trash: Image { Ph.trash.duotone }
    static var trashFill: Image { Ph.trash.fill }
    static var pencil: Image { Ph.pencil.duotone }
    static var gear: Image { Ph.gear.duotone }
    static var gearFill: Image { Ph.gear.fill }
    static var magnifyingGlass: Image { Ph.magnifyingGlass.duotone }
    static var info: Image { Ph.info.duotone }
    static var infoFill: Image { Ph.info.fill }
    static var warning: Image { Ph.warning.duotone }
    static var warningFill: Image { Ph.warning.fill }
    static var lock: Image { Ph.lock.duotone }
    static var lockFill: Image { Ph.lock.fill }
    static var eye: Image { Ph.eye.duotone }
    static var eyeFill: Image { Ph.eye.fill }
    static var tray: Image { Ph.tray.duotone }

    static var users: Image { Ph.users.duotone }
    static var usersFill: Image { Ph.users.fill }
    static var userPlus: Image { Ph.userPlus.duotone }
    static var userPlusFill: Image { Ph.userPlus.fill }
    static var chatDots: Image { Ph.chatDots.duotone }
    static var chatDotsFill: Image { Ph.chatDots.fill }
    static var chats: Image { Ph.chats.duotone }
    static var chatsFill: Image { Ph.chats.fill }

    static var creditCard: Image { Ph.creditCard.duotone }
    static var creditCardFill: Image { Ph.creditCard.fill }
    static var receipt: Image { Ph.receipt.duotone }
    static var receiptFill: Image { Ph.receipt.fill }
    static var coins: Image { Ph.coins.duotone }
    static var coinsFill: Image { Ph.coins.fill }
    static var gift: Image { Ph.gift.duotone }
    static var giftFill: Image { Ph.gift.fill }
    static var rocket: Image { Ph.rocket.duotone }
    static var rocketFill: Image { Ph.rocket.fill }

    static var leaf: Image { Ph.leaf.duotone }
    static var leafFill: Image { Ph.leaf.fill }
    static var sealCheck: Image { Ph.sealCheck.duotone }
    static var sealCheckFill: Image { Ph.sealCheck.fill }
    static var medal: Image { Ph.medal.duotone }
    static var medalFill: Image { Ph.medal.fill }
    static var flag: Image { Ph.flag.duotone }
    static var flagFill: Image { Ph.flag.fill }
    static var flagCheckered: Image { Ph.flagCheckered.duotone }
    static var target: Image { Ph.target.duotone }
    static var targetFill: Image { Ph.target.fill }

    static var mapPin: Image { Ph.mapPin.duotone }
    static var mapPinFill: Image { Ph.mapPin.fill }
    static var compass: Image { Ph.compass.duotone }
    static var path: Image { Ph.path.duotone }

    static var link: Image { Ph.link.duotone }
    static var linkBreak: Image { Ph.linkBreak.duotone }
    static var copy: Image { Ph.copy.duotone }
    static var copyFill: Image { Ph.copy.fill }

    static var play: Image { Ph.play.duotone }
    static var playFill: Image { Ph.play.fill }
    static var pause: Image { Ph.pause.duotone }

    static var arrowCircleUp: Image { Ph.arrowCircleUp.duotone }
    static var arrowCircleUpFill: Image { Ph.arrowCircleUp.fill }
    static var arrowCircleDown: Image { Ph.arrowCircleDown.duotone }
    static var arrowCircleDownFill: Image { Ph.arrowCircleDown.fill }

    static var backspace: Image { Ph.backspace.duotone }
    static var backspaceFill: Image { Ph.backspace.fill }

    static var cardsThree: Image { Ph.cards.duotone }
    static var stackSimple: Image { Ph.stackSimple.duotone }
    static var stack: Image { Ph.stack.duotone }

    static var handPalm: Image { Ph.handPalm.duotone }
    static var handPalmFill: Image { Ph.handPalm.fill }

    static var smiley: Image { Ph.smiley.duotone }
    static var smileyFill: Image { Ph.smiley.fill }

    static var circleDashed: Image { Ph.circleDashed.duotone }

    static var listBullets: Image { Ph.listBullets.duotone }

    static var signOut: Image { Ph.signOut.duotone }

    static var waveform: Image { Ph.waveform.duotone }

    static var question: Image { Ph.question.duotone }
}
