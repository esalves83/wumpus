package pcs.ia.wumpus.util;

public class Pose2D {
	
	public Pose2D(int posicaoX, int posicaoY){
		x = posicaoX;
		y = posicaoY;
	}
	
	private int x = 0;	
	private int y = 0;

	public int getX() {
		return x;
	}

	public void setX(int x) {
		this.x = x;
	}

	public int getY() {
		return y;
	}

	public void setY(int y) {
		this.y = y;
	}
}
