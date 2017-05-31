/*
 * Classname             Player
 * 
 * Implementa os atributos do agente que são atualizados de acordo
 * com os valores retornados do Prolog.
 */

package pcs.ia.wumpus.player;

import java.util.ArrayList;
import java.util.List;

import org.newdawn.slick.Image;
import org.newdawn.slick.SlickException;

import pcs.ia.wumpus.util.Constants.PlayerActionDir;
import pcs.ia.wumpus.util.Constants.PlayerType;
import pcs.ia.wumpus.util.Constants.PlayerAction;
import pcs.ia.wumpus.util.Constants;
import pcs.ia.wumpus.util.Pose2D;


public class Player {
	
	public Player(int playerNumber, PlayerType initPlayerType) throws SlickException{
		
		// Imagens do agente em cada orientação (leste,oeste,norte,sul)
		playerUp = new Image(Constants.HUMAN_PLAYER_UP);
		playerDown = new Image(Constants.HUMAN_PLAYER_DOWN);
		playerLeft = new Image(Constants.HUMAN_PLAYER_LEFT);
		playerRight = new Image(Constants.HUMAN_PLAYER_RIGHT);
		
		// Atributos iniciais
		currentPose = playerRight;			// Agente voltado para direita
		setPlayerShortGoal("find_out");		// Objetivo inicial: encontrar o ouro
		playerScore = 0;					// Pontuação inicial
		
	}
	
	private Image currentPose, playerUp, playerDown, playerLeft, playerRight;
	private Pose2D playerPose2D = new Pose2D(Constants.INITIAL_POSE_X,Constants.INITIAL_POSE_Y);
	private Pose2D playerPose2DProlog = new Pose2D(1,1);
	//private List<Pose2D> playerPosesVisited = new ArrayList<Pose2D>();
	private int playerPosesVisited = 1;
	private List<Pose2D> playerInferedPositions = new ArrayList<Pose2D>();
	private PlayerAction playerAction;
	private PlayerActionDir playerActionDir = PlayerActionDir.RIGHT;
	private boolean alive = true;
	private int playerEnergy = 1000;
	private boolean foundGold = false, foundExit = false;
	private boolean killedWumpus = false;
	private boolean stench = false, breeze = false, glitter = false, bump = false, scream = false;
	private boolean agent_in_cave = true;
	
	private String short_goal = null;
	private String agent_goal = null;
	private int step_number = 0;
	private int playerScore;
	
	/**
	 * Reset atributos
	 */
	public void reset(){
		
		// Posição e orientação iniciais
		playerPose2D.setX(Constants.INITIAL_POSE_X);
		playerPose2D.setY(Constants.INITIAL_POSE_Y);
		playerActionDir = PlayerActionDir.RIGHT;
		currentPose = playerRight;
		
		playerPose2DProlog.setX(1);
		playerPose2DProlog.setY(1);
		
		// Limpar lista de salas visitadas
		//playerPosesVisited.clear();
		playerPosesVisited = 1;
		playerInferedPositions.clear();		
		
		// Outros atributos
		alive = true;
		playerEnergy = 1000;		
		foundGold = false; foundExit = false;
		killedWumpus = false;
		stench = false; breeze = false; glitter = false; bump = false; scream = false;
		setPlayerShortGoal("find_out");
		setPlayerAgentGoal("find_out");
		step_number = 0;
		playerScore = 0;
		agent_in_cave = true;
	}
	
	/**
	 * Get/Set imagens da orientação do agente -> (up, down, left, right)
	 */
	public Image getPose() {
		return currentPose;
	}
	public void setPose(Image pose) {
		this.currentPose = pose;
	}
	public Image getPlayerUp() {
		return playerUp;
	}
	public void setPlayerUp(Image pose) {
		this.playerUp = pose;
	}
	public Image getPlayerDown() {
		return playerDown;
	}
	public void setPlayerDown(Image pose) {
		this.playerDown = pose;
	}
	public Image getPlayerLeft() {
		return playerLeft;
	}
	public void setPlayerLeft(Image pose) {
		this.playerLeft = pose;
	}
	public Image getPlayerRight() {
		return playerRight;
	}
	public void setPlayerRight(Image pose) {
		this.playerRight = pose;
	}
	
	/**
	 * Get/Set localização [x,y] do agente
	 */
	public Pose2D getPlayerPose2D() {
		return playerPose2D;
	}
	public void setPlayerPose2D(Pose2D pos) {
		this.playerPose2D = pos;
	}
	
	public Pose2D getPlayerPose2DProlog() {
		return playerPose2DProlog;
	}
	public void setPlayerPose2DProlog(Pose2D pos) {
		this.playerPose2DProlog = pos;
	}
	
	/**
	 * Get/Set posições visitadas
	 */
	public int getPlayerPosesVisited() {
		return playerPosesVisited;
	}
	public void setPlayerPosesVisited(int p) {
		this.playerPosesVisited = p;
	}
	
	/**
	 * Get/Set ações do agente (mover,atirar,pegar,sair,...)
	 */
	public PlayerAction getPlayerAction() {
		return playerAction;
	}
	public void setPlayerAction(PlayerAction action) {
		this.playerAction = action;
	}
	public PlayerActionDir getPlayerActionDir() {
		return playerActionDir;
	}
	public void setPlayerActionDir(PlayerActionDir dir) {
		this.playerActionDir = dir;
	}
	
	/**
	 * Get/Set percepções do agente (stenchy,breeze,glitter,bump,scream)
	 */
	public boolean isStench() {
		return stench;
	}
	public void setStench(boolean value) {
		this.stench = value;
	}
	public boolean isBreeze() {
		return breeze;
	}
	public void setBreeze(boolean value) {
		this.breeze = value;
	}
	public boolean isGlitter() {
		return glitter;
	}
	public void setGlitter(boolean value) {
		this.glitter = value;
	}
	public boolean isBump() {
		return bump;
	}
	public void setBump(boolean value) {
		this.bump = value;
	}
	public boolean isScream() {
		return scream;
	}
	public void setScream(boolean value) {
		this.scream = value;
	}
	
	/**
	 * Get/Set objetivo atual do agente
	 */
	public String getPlayerShortGoal() {
		return short_goal;
	}
	public void setPlayerShortGoal(String sg) {
		this.short_goal = sg;
	}
	
	/**
	 * Get/Set estratégia do agente
	 */
	public String getPlayerAgentGoal() {
		return agent_goal;
	}
	public void setPlayerAgentGoal(String ag) {
		this.agent_goal = ag;
	}
	
	/**
	 * Get/Set saúde do agente
	 */
	public boolean isAlive() {
		return alive;
	}
	public void setAlive(boolean value) {
		this.alive = value;
	}
	public int getPlayerEnergy() {
		return playerEnergy;
	}
	public void setPlayerEnergy(int energy) {
		this.playerEnergy = energy;
	}
	
	/**
	 * Get/Set agente encontrou o ouro e saída
	 */
	public boolean isfoundGold() {
		return foundGold;
	}
	public void setFoundGold(boolean gold) {
		this.foundGold = gold;
	}
	public boolean isfoundExit() {
		return foundExit;
	}
	public void setFoundExit(boolean exit) {
		this.foundExit = exit;
	}
	
	public List<Pose2D> getPlayerInferedPositions() {
		return playerInferedPositions;
	}
	
	public void setPlayerInferedPositions(List<Pose2D> pos) {
		this.playerInferedPositions = pos;
	}
	
	/**
	 * Get/Set wumpus morto (true/false)
	 */
	public boolean iskilledWumpus() {
		return killedWumpus;
	}
	public void setkilledWumpus(boolean kill) {
		this.killedWumpus = kill;
	}
	
	/**
	 * Get/Set agente na caverna (true/false)
	 */
	public boolean isAgentInCave() {
		return agent_in_cave;
	}
	public void setAgentInCave(boolean ac) {
		this.agent_in_cave = ac;
	}
	
	/**
	 * Get/Set número do passo do agente
	 */
	public int getPlayerStepNumber() {
		return step_number;
	}
	public void setPlayerStepNumber(int num) {
		this.step_number = num;
	}
	
	/**
	 * Get/Set pontuação do agente
	 */
	public int getPlayerScore() {
		return playerScore;
	}
	public void setPlayerScore(int num) {
		this.playerScore = num;
	}
}
