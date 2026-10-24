import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_stepByPage: stepByPageCheck.checked
    property alias cfg_loopNavigation: loopCheck.checked
    property alias cfg_showTooltip: tooltipCheck.checked
    property alias cfg_iconCircleSize: sizeSpinBox.value

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: stepByPageCheck
            Kirigami.FormData.label: i18n("Navigation:")
            text: i18n("Navigate 6 apps at once (Page by page)")
        }

        QQC2.CheckBox {
            id: loopCheck
            Kirigami.FormData.label: i18n("Carousel:")
            text: i18n("Loop around when reaching end or beginning")
        }

        QQC2.CheckBox {
            id: tooltipCheck
            Kirigami.FormData.label: i18n("Display:")
            text: i18n("Show application name tooltip on hover")
        }

        QQC2.SpinBox {
            id: sizeSpinBox
            Kirigami.FormData.label: i18n("Icon Circle Size:")
            from: 40
            to: 68
            stepSize: 2
        }
    }
}
