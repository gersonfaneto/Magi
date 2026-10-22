/**
 * Selection arithmetic shared by the pill's keyboard navigation. Every list
 * surface keeps its own index; these helpers only decide the next one, so the
 * key contract (wrap for menus, clamp for settings) lives in one place.
 *
 * `index < 0` means "nothing focused yet": the first step lands on the row the
 * direction came from, so Up starts at the last row and Down at the first.
 */

function clamp(n, lo, hi) {
    return Math.max(lo, Math.min(hi, n));
}

function step(index, count, delta, wrap) {
    if (count <= 0)
        return -1;
    if (index < 0)
        return delta > 0 ? 0 : count - 1;
    var next = index + delta;
    if (wrap)
        return ((next % count) + count) % count;
    return clamp(next, 0, count - 1);
}

/** One viewport, expressed as a row delta; PAGE is the caller's row count. */
function page(index, count, dir, pageSize, wrap) {
    return step(index, count, dir * Math.max(1, pageSize), wrap);
}

/** First (-1) or last (+1) row, or -1 for an empty list. */
function edge(count, dir) {
    if (count <= 0)
        return -1;
    return dir < 0 ? 0 : count - 1;
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { clamp, step, page, edge };
}
