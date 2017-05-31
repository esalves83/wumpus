#/bin/bash

java -Djava.library.path=libs/swipl-7.4.2/lib/x86_64-linux:libs/slick/lib/natives-linux -Dfile.encoding=UTF-8 -classpath bin:libs/guava.jar:libs/swipl-7.4.2/lib/jpl.jar:libs/slick/lib/lwjgl.jar:libs/slick/lib/slick.jar pcs.ia.wumpus.WumpusWorld
