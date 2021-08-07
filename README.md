# bashtet
Bashtet is a [Tetris Bot Protocol](https://github.com/tetris-bot-protocol/tbp-spec/) Tetris bot written in bash. Use it with a TBP frontend, such as [Quadspace](https://github.com/SoRA-X7/Quadspace/).<br>
The actual AI itself is a simplified implementation of [Yiyuan Lee](https://codemyroad.wordpress.com/2013/04/14/tetris-ai-the-near-perfect-player/)'s Tetris AI, which was chosen over [Dellacherie](https://www.colinfahey.com/tetris/tetris.html)'s algorithm or [El-Tetris](https://imake.ninja/el-tetris-an-improvement-on-pierre-dellacheries-algorithm/) as it was a fairly simple algorithm using just four features. Despite the name, this algorithm is nowhere near perfect.

### ...Why?
TBP's design delegates actual legality checking for each move to the frontend; I thought it would be funny to abuse this fact. The idea was to enumerate each move and simply present it to the frontend in order of preference. Alas, this was incredibly slow and also crashed Quadspace (why can't it handle a thousand suggestions?), so this does some basic legality checks to avoid this.
