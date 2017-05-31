package pcs.ia.wumpus.util;

public class Constants {
	
	// Static images
	public static final String HUMAN_PLAYER_UP = "data/jogHCima.png";
	public static final String HUMAN_PLAYER_DOWN = "data/jogHBaixo.png";
	public static final String HUMAN_PLAYER_LEFT = "data/jogHEsq.png";
	public static final String HUMAN_PLAYER_RIGHT = "data/jogHDir.png";
	
	public static final String AGENT_PLAYER_UP = "data/jogRCima.png";
	public static final String AGENT_PLAYER_DOWN = "data/jogRBaixo.png";
	public static final String AGENT_PLAYER_LEFT = "data/jogREsq.png";
	public static final String AGENT_PLAYER_RIGHT = "data/jogRDir.png";
	
	public static final int INITIAL_POSE_X = 34*2;
	public static final int INITIAL_POSE_Y = (34*18)-20;
	
	public static enum ObjectType {
		WALL , 
		GOLD,
		BRIGHTNESS,
		WUMPUS,
		STENCH,
		PIT,
		BREEZE,
		PLAYER,
		EXIT
	}
	
	public static enum PlayerAction {
		MOVE,
		SHOOT_ARROW
	}
	
	public static enum PlayerHealthy {
		ALIVE,
		DEAD
	}
	
	public static enum DescTotal {
		AGENT_HEALTHY,
		AGENT_GOAL,
		WUMPUS_HEALTHY,
		NB_VISITED,
		AGENT_SCORE,
		AGENT_HOLD,
		AGENT_IN_CAVE,
		TIME
	}
	
	public static enum PlayerActionDir {
		UP,
		DOWN,
		LEFT,
		RIGHT
	}
	
	public static enum PlayerType {
		HUMAN,
		AGENT
	}

}
