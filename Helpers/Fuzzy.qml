// Stealing https://github.com/SirEthanator/Quickshell-WIP/blob/main/widgets/menu/launcher/Index.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
	readonly property real prefixWeight: 0.2
	readonly property real distanceWeight: 0.3
	readonly property real consecutiveWeight: 0.5

	function levenshteinDistance(a: string, b: string): int {
		// If one string is empty, the distance is the length of the other string
		// (e.g. a blank string is 3 deletions away from "the")
		if (a.length === 0)
			return b.length;
		if (b.length === 0)
			return a.length;

		let matrix = [];

		// Initialise matrix with dimensions (b.length+1) x (a.length+1)

		// Initialise first column
		// Creates a column with 1,2,3...
		for (let i = 0; i <= b.length; i++) {
			matrix[i] = [i];
		}

		// Initialise first row
		// Creates a row with 1,2,3...
		for (let i = 0; i <= a.length; i++) {
			matrix[0][i] = i;
		}

		// Fill the matrix, for each cell [i][j], we calculate the minimum cost
		// to transform b[0..i-1] into a[0..j-1]
		for (let i = 1; i <= b.length; i++) {
			for (let j = 1; j <= a.length; j++) {

				// Check if current characters match
				if (b.charAt(i - 1) === a.charAt(j - 1)) {
					// Characters match: cost of 0, take diagonal value
					// This represents transforming b[0..i-2] to a[0..j-2]
					matrix[i][j] = matrix[i - 1][j - 1];
				} else {
					matrix[i][j] = Math.min(matrix[i - 1][j - 1] + 1  // Substitution: replace b[i-1] with a[j-1]
					, matrix[i][j - 1] + 1    // Insertion: insert a[j-1] into b
					, matrix[i - 1][j] + 1     // Deletion: delete b[i-1] from b
					);
				}
			}
		}

		// The bottom right cell contains the distance:
		// minimum edit distance between the complete strings a and b
		return matrix[b.length][a.length];

	// Example matrix for mitten -> sitting:
	//
	//    "" m i t t e n
	// ""  0 1 2 3 4 5 6
	// s   1 1 2 3 4 5 6
	// i   2 2 1 2 3 4 5
	// t   3 3 2 1 2 3 4
	// t   4 4 3 2 1 2 3
	// i   5 5 4 3 2 2 3
	// n   6 6 5 4 3 3 2
	// g   7 7 6 5 4 4 3
	//
	// Result: 3 (sub k -> s, sub e -> i, insert g)
	}

	// Calculate the similarity ratio between two strings (0-1, case sensitive)
	function distanceScore(a: string, b: string): real {
		const maxLen = Math.max(a.length, b.length);
		if (maxLen === 0)
			return 1;

		const distance = levenshteinDistance(a, b);
		return (maxLen - distance) / maxLen;
	}

	function prefixScore(q: string, t: string): real {
		if (t.startsWith(q)) {
			// 0.9 for prefix, 1.0 for exact match
			return q.length === t.length ? 1.0 : 0.9;
		}

		// Check if query matches other words' beginnings
		const words = t.split(" ");
		for (const word of words) {
			if (word.startsWith(q)) {
				return q.length === word.length ? 0.9 : 0.8;
			}
		}

		return 0;  // Not a prefix
	}

	function consecutiveScore(q: string, t: string): real {
		let longestConsecutive = 0;
		let currentConsecutive = 0;
		let targetIdx = 0;

		for (let i = 0; i < q.length; i++) {
			const found = t.indexOf(q[i], targetIdx);
			if (found === -1) {
				currentConsecutive = 0;
				continue;
			}

			if (found === targetIdx) {
				currentConsecutive++;
				longestConsecutive = Math.max(longestConsecutive, currentConsecutive);
			} else {
				currentConsecutive = 1;
			}

			targetIdx = found + 1;
		}

		return longestConsecutive / q.length;
	}

	function getScore(q: string, t: string): real {
		return ((distanceScore(q, t) * distanceWeight) + (prefixScore(q, t) * prefixWeight) + (consecutiveScore(q, t) * consecutiveWeight));
	}

	function fuzzySearch(items: var, query: string, key: string, threshold: real): var {
		threshold = threshold || 0.60;
		key = key || null;

		if (!query || query.length === 0) {
			return items;
		}

		query = query.toLowerCase();

		let result = [];

		for (let i = 0; i < items.length; i++) {
			const item = items[i];
			const searchText = (!!key ? item[key] : item).toLowerCase();

			if (typeof searchText !== 'string') {
				continue;
			}

			let score = getScore(query, searchText);

			if (score >= threshold) {
				result.push({
					item: item,
					score: score
				});
			}
		}

		result.sort((a, b) => b.score - a.score);

		return result.map(item => item.item);
	}
}
