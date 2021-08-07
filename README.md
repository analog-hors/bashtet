# bashtet
Bashtet is a [Tetris Bot Protocol](https://github.com/tetris-bot-protocol/tbp-spec/) Tetris bot written in bash. Use it with a TBP frontend, such as [Quadspace](https://github.com/SoRA-X7/Quadspace/).

### ...Why?
TBP's design delegates actual legality checking for each move to the frontend; I thought it would be funny to abuse this fact. The idea was to enumerate each move and simply present it to the frontend in order of preference. Alas, this was incredibly slow and also crashed Quadspace (why can't it handle a thousand suggestions?), so this does some basic legality checks to avoid this.
