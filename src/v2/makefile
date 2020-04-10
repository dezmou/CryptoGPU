bake: bake.cu broker.cu trade.cu analyse.cu trade.h
	nvcc -D BUILD bake.cu -o bake

play : play.cu broker.cu trade.cu analyse.cu trade.h
	nvcc -D BUILD -D PLAY play.cu -o play

replay : play.cu broker.cu trade.cu analyse.cu trade.h
	nvcc -D BUILD -D PLAY -D REPLAY play.cu -o replay

