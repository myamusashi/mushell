import QtQuick

import qs.Configs
import qs.Services

Text {
    id: root

    property string searchText: ""
    property string fullText: ""
    property color highlightColor: Colours.m3Colors.m3Primary
	property color normalColor: Colours.m3Colors.m3OnSurface

	font.family: Appearance.fonts.family.sans
    textFormat: Text.RichText

    function normalizeChar(character) {
        const charMap = {
            "a": 'aàáâãäåāăą4@',
            "e": 'eèéêëēėę3',
            "i": 'iìíîïīįı1!|l',
            "o": 'oòóôõöøōő0',
            "u": 'uùúûüūůű',
            "c": 'cçćč',
            "n": 'nñńň',
            "s": 'sśšş5$',
            "z": 'zźżž2',
            "l": 'l1!|i',
            "g": 'g9',
            "t": 't7+'
        };

        const lower = character.toLowerCase();
        for (const key in charMap) {
            if (charMap[key].indexOf(lower) !== -1) {
                return key;
            }
        }
        return lower;
    }

    function escapeHtml(text) {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
    }

    function getHighlightedText() {
        if (!searchText || searchText.length === 0) {
            return escapeHtml(fullText);
        }

        const normalizedSearch = searchText.toLowerCase().split('').map(c => normalizeChar(c));
        const normalizedFull = fullText.toLowerCase().split('').map(c => normalizeChar(c));

        let matchPositions = new Set();
        let searchIdx = 0;

        for (let i = 0; i < normalizedFull.length && searchIdx < normalizedSearch.length; i++) {
            if (normalizedFull[i] === normalizedSearch[searchIdx]) {
                matchPositions.add(i);
                searchIdx++;
            }
        }

        if (searchIdx < normalizedSearch.length) {
            matchPositions.clear();
            searchIdx = 0;

            for (let i = 0; i < normalizedFull.length && searchIdx < normalizedSearch.length; i++) {
                if (normalizedFull[i] === normalizedSearch[searchIdx]) {
                    matchPositions.add(i);
                    searchIdx++;
                }
            }
        }

        let result = '';
        for (let i = 0; i < fullText.length; i++) {
            const characters = escapeHtml(fullText[i]);
            if (matchPositions.has(i)) {
                result += `<span style="color: ${highlightColor}; font-weight: 600;">${characters}</span>`;
            } else {
                result += `<span style="color: ${normalColor};">${characters}</span>`;
            }
        }

        return result;
    }

    text: getHighlightedText()

    onSearchTextChanged: text = getHighlightedText()
    onFullTextChanged: text = getHighlightedText()
}
