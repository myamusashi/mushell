pragma Singleton

import Quickshell
import QtQuick

Singleton {
	readonly property real prefixWeight: 0.3
	readonly property real distanceWeight: 0.3
	readonly property real consecutiveWeight: 0.25
	readonly property real wordBoundaryWeight: 0.15

	// Character similarity map for look-alike matching
	readonly property var charMap: ({
			'a': 'aàáâãäåāăą4@',
			'e': 'eèéêëēėę3',
			'i': 'iìíîïīįı1!|l',
			'o': 'oòóôõöøōő0',
			'u': 'uùúûüūůű',
			'c': 'cçćč',
			'n': 'nñńň',
			's': 'sśšş5$',
			'z': 'zźżž2',
			'l': 'l1!|i',
			'g': 'g9',
			't': 't7+'
		})

	function normalizeChar(chars: string): string {
		const lower = chars.toLowerCase();
		for (const key in charMap) {
			if (charMap[key].indexOf(lower) !== -1) {
				return key;
			}
		}
		return lower;
	}

	function normalizeText(text: string): string {
		let result = '';
		for (let i = 0; i < text.length; i++) {
			result += normalizeChar(text[i]);
		}
		return result;
	}

	function levenshteinDistance(a: string, b: string): int {
		if (a.length === 0)
			return b.length;
		if (b.length === 0)
			return a.length;

		const shorter = a.length <= b.length ? a : b;
		const longer = a.length <= b.length ? b : a;

		let prevRow = new Array(shorter.length + 1);
		let currRow = new Array(shorter.length + 1);

		for (let i = 0; i <= shorter.length; i++) {
			prevRow[i] = i;
		}

		for (let i = 1; i <= longer.length; i++) {
			currRow[0] = i;

			for (let j = 1; j <= shorter.length; j++) {
				const cost = longer[i - 1] === shorter[j - 1] ? 0 : 1;

				currRow[j] = Math.min(prevRow[j] + 1, currRow[j - 1] + 1, prevRow[j - 1] + cost);
			}

			[prevRow, currRow] = [currRow, prevRow];
		}

		return prevRow[shorter.length];
	}

	function distanceScore(a: string, b: string): real {
		const maxLen = Math.max(a.length, b.length);
		if (maxLen === 0)
			return 1;

		const distance = levenshteinDistance(a, b);
		const normalized = (maxLen - distance) / maxLen;

		return Math.pow(normalized, 1.5);
	}

	function prefixScore(q: string, t: string, tWords: var): real {
		if (t.indexOf(q) === 0) {
			return q.length === t.length ? 1.0 : 0.95;
		}

		for (let i = 0; i < tWords.length; i++) {
			if (tWords[i].indexOf(q) === 0) {
				return q.length === tWords[i].length ? 0.9 : 0.85;
			}
		}

		return 0;
	}

	function consecutiveScore(q: string, t: string): real {
		if (q.length === 0)
			return 1;

		let best = 0;
		let current = 0;
		let qIdx = 0;

		for (let i = 0; i < t.length && qIdx < q.length; i++) {
			if (t[i] === q[qIdx]) {
				current++;
				qIdx++;
				best = Math.max(best, current);
			} else {
				current = 0;
			}
		}

		const ratio = best / q.length;
		return ratio * ratio;
	}

	function wordBoundaryScore(q: string, tWords: var): real {
		let bestScore = 0;

		for (let i = 0; i < tWords.length; i++) {
			const word = tWords[i];
			if (word.indexOf(q) !== -1) {
				const wordScore = q.length / word.length;
				bestScore = Math.max(bestScore, wordScore);
			}
		}

		return bestScore;
	}

	function getScore(q: string, t: string, tWords: var): real {
		const lenRatio = Math.min(q.length, t.length) / Math.max(q.length, t.length);
		if (lenRatio < 0.3) {
			return 0;
		}

		const distance = distanceScore(q, t) * distanceWeight;
		const prefix = prefixScore(q, t, tWords) * prefixWeight;
		const consecutive = consecutiveScore(q, t) * consecutiveWeight;
		const wordBoundary = wordBoundaryScore(q, tWords) * wordBoundaryWeight;

		return distance + prefix + consecutive + wordBoundary;
	}

	function fuzzySearch(items: var, query: string, key: string, threshold: real): var {
		if (typeof threshold === 'undefined') {
			threshold = 0.55;
		}

		if (!query || query.length === 0) {
			return items;
		}

		const normalizedQuery = normalizeText(query).trim();

		if (normalizedQuery.length === 0) {
			return items;
		}

		let results = [];

		for (let i = 0; i < items.length; i++) {
			const item = items[i];
			const searchText = key ? item[key] : item;

			if (typeof searchText !== 'string') {
				continue;
			}

			const normalizedText = normalizeText(searchText);

			if (normalizedText === normalizedQuery) {
				results.push({
					item: item,
					score: 1.0
				});
				continue;
			}

			if (normalizedText.indexOf(normalizedQuery) !== -1) {
				results.push({
					item: item,
					score: 0.95
				});
				continue;
			}

			const words = normalizedText.split(/\s+/);
			const score = getScore(normalizedQuery, normalizedText, words);

			if (score >= threshold) {
				results.push({
					item: item,
					score: score
				});
			}
		}

		results.sort((a, b) => {
			const scoreDiff = b.score - a.score;
			if (Math.abs(scoreDiff) < 0.001) {
				const aText = key ? a.item[key] : a.item;
				const bText = key ? b.item[key] : b.item;
				return aText.length - bText.length;
			}
			return scoreDiff;
		});

		return results.map(r => r.item);
	}
}
