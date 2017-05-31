/*
 * Classname             WumpusWorld
 * 
 * Classe principal
 * Responsável por renderizar os objetos e interação com usuário
 * Executa leitura do teclado e imprime os resultados obtidos no Prolog
 */

package pcs.ia.wumpus;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import org.lwjgl.Sys;
import org.newdawn.slick.Animation;
import org.newdawn.slick.AppGameContainer;
import org.newdawn.slick.BasicGame;
import org.newdawn.slick.Color;
import org.newdawn.slick.GameContainer;
import org.newdawn.slick.Graphics;
import org.newdawn.slick.Image;
import org.newdawn.slick.Input;
import org.newdawn.slick.SlickException;
import org.newdawn.slick.tiled.TiledMap;

import com.google.common.collect.Multimap;

import pcs.ia.wumpus.player.Player;
import pcs.ia.wumpus.prolog.PrologInterface;
import pcs.ia.wumpus.util.Constants.ObjectType;
import pcs.ia.wumpus.util.Constants.PlayerType;
import pcs.ia.wumpus.util.Pose2D;

public class WumpusWorld extends BasicGame {
	
	static AppGameContainer app;
	
	String msgPanel1 = new String();
	String msgPanel2 = new String();
	String msgPanel3 = new String();
	String msgPanel4 = new String();
	String msgPanel5 = new String();
	String msgPanel6 = new String();
	String msgPanel7 = new String();
	String msgPanel8 = new String();
	
	private TiledMap MapScene;
	
	PrologInterface prolog;
	
	// Player objects
	private Player player;
	
	Multimap<ObjectType, Pose2D> world_objects = null;
	
	String agent_healthy = null;
	String short_goal = null;
	
	private Animation wumpus, wumpus_dead;
	private Image gold, cave, exit;
	
	List<Pose2D> playerVisitedPositions = new ArrayList<Pose2D>();
	List<Pose2D> playerInferedPositions = new ArrayList<Pose2D>();
	
	boolean wumpus_killed = false;
	boolean holding_gold = false;
	boolean is_started = false;
	boolean is_finished = false;

	public WumpusWorld() {
		super("WumpusWorld");
		// TODO Auto-generated constructor stub
	}
	
	@Override
	public void keyPressed(int key, char c){
		
		// Time to make actions
		try {
			TimeUnit.MILLISECONDS.sleep(100);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		
		if (key == Input.KEY_S && player != null){
			is_started = true;
		}
		if (key == Input.KEY_A && player != null){
			if(is_started)
				prologStep();
		}
		if (key == Input.KEY_R && player != null){
			prologRestart(player);
			is_started = false;
		}
	}

	public void render(GameContainer arg0, Graphics arg1) throws SlickException {
		// TODO Auto-generated method stub
		// This is where all your graphics is done.
		
		int delta = 170;
		int x,y;
		Pose2D pose = new Pose2D(0,0); 
		
		// draw map
		MapScene.render(0,0);
		
		// draw objects
		Set<ObjectType> keys =  world_objects.keySet();
		Iterator<ObjectType> i = keys.iterator();
		while (i.hasNext()){
			
			ObjectType object = i.next();
			
			Collection<Pose2D> pos =  world_objects.get(object);
			Iterator<Pose2D> ipos = pos.iterator();
			
			switch (object) {
			
				case GOLD:
					pose = ipos.next();
					x = pose.getX();
					y = pose.getY();
					if(player.isfoundGold()){
						gold.draw(68+((x-1)*delta), 592-((y-1)*delta), 0.01f);
						exit.draw(68, 592, 2.0f);
					}
					else
						gold.draw(68+((x-1)*delta), 592-((y-1)*delta), 1.5f);
					break;
					
				case WUMPUS:
					pose = ipos.next();
					x = pose.getX();
					y = pose.getY();
					if (!player.iskilledWumpus())
						wumpus.draw(68+((x-1)*delta), 592-((y-1)*delta), 100.0f, 100.f);
					else
						wumpus_dead.draw(68+((x-1)*delta), 592-((y-1)*delta), 100.0f, 100.f);
					break;
					
				case PIT:
					while (ipos.hasNext()){
						pose = ipos.next();
						x = pose.getX();
						y = pose.getY();
						cave.draw(68+((x-1)*delta), 592-((y-1)*delta), 2.0f);
					}
					break;
					
				default:
					break;			
			}
			
		}
		
		drawPanel(arg1);
		
		drawPlayer();		
	}

	public void init(GameContainer container) throws SlickException {
		// TODO Auto-generated method stub
		/* You can put code here to set things up for your game, such as
		 * loading resources like images and sounds.
		 */
		
		// *** Map initialization
		MapScene = new TiledMap("data/map_scene.tmx");
		
		// *** Player initialization
		try {
			player = new Player(1,PlayerType.AGENT);
		} catch (SlickException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		prolog = new PrologInterface();
		
		world_objects = PrologInterface.consultObjects();
		
		// *** Image animations
		Image[] wumpusAnimation = { new Image("data/wumpus.png"),new Image("data/wumpus_alt.png")};
		Image[] wumpusDeadAnimation = { new Image("data/wumpusM.png"),new Image("data/wumpusM_alt.png")};
		
		// *** Static images
		gold = new Image("data/ouro.png");
		cave = new Image("data/caverna.png");
		exit = new Image("data/sair.png");
		
		// *** Animation time
		int[] wumpusTime = {1500, 1500};
		int[] genericTime = {600, 600};
		
		// *** Initialize animations
		wumpus = new Animation(wumpusAnimation, wumpusTime, true);
		wumpus_dead = new Animation(wumpusDeadAnimation, genericTime, true);		
		
		container.getGraphics().setBackground(Color.gray);
		container.setAlwaysRender(true);
		container.setMinimumLogicUpdateInterval(300);
		container.getInput().enableKeyRepeat();

	}
	
	public void update(GameContainer container, int delta)
			throws SlickException {
		// TODO Auto-generated method stub
		// This is where the game logic is done.
		if(player.getPlayerShortGoal().equals("die_wumpus")){
			Sys.alert("Warning", "Game Over! Killed by Wumpus...");
			container.exit();
			player.setAlive(false);
		}
		if(player.getPlayerShortGoal().equals("die_pit")){
			Sys.alert("Warning", "Game Over! Fallen in a pit...");
			container.exit();
			player.setAlive(false);
		}
	}
	
	public void prologStep() {
		PrologInterface.oneStep(player);
	}
	
	public void prologRestart(Player p) {
		PrologInterface.prologRestart();
		p.reset();
	}
	
	private void drawPanel(Graphics g){
		
		int meioBloco = 34/2;
		int alinhamentoEsquerda = (34*21) + 10;
		String agent_status = null, agent_perceptions = null;
		
		g.drawString("Wumpus World Infos", alinhamentoEsquerda, meioBloco);
				
		g.drawString("Hit:", alinhamentoEsquerda, meioBloco*3);
		g.drawString("S -> start the game", alinhamentoEsquerda, meioBloco*4);
		g.drawString("A -> agent step-by-step", alinhamentoEsquerda, meioBloco*5);
		g.drawString("R -> restart", alinhamentoEsquerda, meioBloco*6);
		
		g.drawImage(gold, alinhamentoEsquerda, meioBloco * 8);
		g.drawString("Gold", alinhamentoEsquerda + meioBloco * 3, meioBloco * 8);		
		
		g.drawAnimation(wumpus, alinhamentoEsquerda, meioBloco * 10);
		g.drawString("Wumpus", alinhamentoEsquerda + meioBloco * 3, meioBloco * 10);
		
		g.drawImage(cave, alinhamentoEsquerda, meioBloco * 12);
		g.drawString("Cave", alinhamentoEsquerda + meioBloco * 3, meioBloco * 12);
		
		agent_status = "I'm in ("+player.getPlayerPose2DProlog().getX()+","+player.getPlayerPose2DProlog().getY()+
			    ") facing to "+player.getPlayerActionDir();
		
		agent_perceptions = "I feel...";
		if(player.isStench())
			agent_perceptions += " stenchy";
		if(player.isBreeze())
			agent_perceptions += " breeze";
		if(player.isGlitter())
			agent_perceptions += " glittering";
		if(player.isScream())
			agent_perceptions += " scream";
		if(!player.isStench()&& !player.isBreeze()&& !player.isGlitter()&& !player.isBump()&& !player.isScream())
			agent_perceptions += " nothing";
		
		if(player.isBump())
			agent_perceptions = "I bumped the wall!";
		
		short_goal = player.getPlayerShortGoal();
		if(short_goal.contains("shoot") && player.iskilledWumpus())
			agent_perceptions = "I shoot the Wumpus and I killed him...";
		else if(short_goal.contains("shoot") && !player.iskilledWumpus())
			agent_perceptions = "I shoot the Wumpus but I missed!";
		if(short_goal.equals("grab_gold"))
			agent_perceptions = "Yomi! Yomi! Give me the money...";
		
		if(short_goal.equals("go_out___climb") || short_goal.equals("nothing_more")){
			is_finished = true;
			if(!player.isAgentInCave() && player.iskilledWumpus() && player.isfoundGold())
				g.drawString("I am the best!", alinhamentoEsquerda, meioBloco * 24);
			if(!player.isAgentInCave() && !player.iskilledWumpus() && player.isfoundGold())
				g.drawString("It's too easy!", alinhamentoEsquerda, meioBloco * 24);
			if(!player.isAgentInCave() && player.iskilledWumpus() && !player.isfoundGold())
				g.drawString("I can't find the gold! I'm too tired", alinhamentoEsquerda, meioBloco * 24);
			if(!player.isAgentInCave() && !player.iskilledWumpus() && !player.isfoundGold())
				g.drawString("I am sure Wumpus has moved!", alinhamentoEsquerda, meioBloco * 24);
			if(player.isAgentInCave() && !player.iskilledWumpus() && !player.isfoundGold())
				g.drawString("I give up!", alinhamentoEsquerda, meioBloco * 24);
		}
		
		if(is_started){
			g.drawString("Step: "+player.getPlayerStepNumber(), alinhamentoEsquerda, meioBloco * 16);
			g.drawString(agent_status, alinhamentoEsquerda, meioBloco * 17);
			g.drawString(agent_perceptions, alinhamentoEsquerda, meioBloco * 18);
			g.drawString("Agent score: "+player.getPlayerScore(), alinhamentoEsquerda, meioBloco * 20);
			g.drawString("# rooms visited: "+player.getPlayerPosesVisited(), alinhamentoEsquerda, meioBloco * 22);
			
			if(short_goal.contains("kill_wumpus"))
			{
				g.drawString("There is no more good rooms", alinhamentoEsquerda, meioBloco * 26);
				g.drawString("I don't grab the gold", alinhamentoEsquerda, meioBloco * 27);
				g.drawString("Wumpus is alive", alinhamentoEsquerda, meioBloco * 28);
				g.drawString("I'm motivated to kill him", alinhamentoEsquerda, meioBloco * 29);
			}
			if(short_goal.contains("hurry"))
			{
				g.drawString("Yes! I killed the Wumpus", alinhamentoEsquerda, meioBloco * 26);
				g.drawString("Let's try to find the gold", alinhamentoEsquerda, meioBloco * 27);
			}
			if(short_goal.contains("find_out") || short_goal.contains("rebound"))
				g.drawString("I'm trying to find the gold", alinhamentoEsquerda, meioBloco * 26);
			if(short_goal.contains("go_out"))
				g.drawString("I'm trying to go out the cave", alinhamentoEsquerda, meioBloco * 26);
		}
		else
			g.drawString("Hit S to start the game!", alinhamentoEsquerda, meioBloco * 16);
	}
	
	private void drawPlayer(){
		
		if (player != null && player.isAlive()){
			
			int x = player.getPlayerPose2D().getX();
			int y = player.getPlayerPose2D().getY();
			
			switch (player.getPlayerActionDir()) {
			case UP:
				player.setPose(player.getPlayerUp()); // turn player up
				break;
			case DOWN:
				player.setPose(player.getPlayerDown()); // turn player down
				break;
			case LEFT:
				player.setPose(player.getPlayerLeft()); // turn player left
				break;
			case RIGHT:
				player.setPose(player.getPlayerRight()); // turn player right
				break;
			default:
				break;
			}
			
			player.getPose().draw(x, y, 2.0f);
		}
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		try {	
			app = new AppGameContainer(new WumpusWorld());
			app.setDisplayMode(1050, 714, false);
			//app.setFullscreen(true);
			app.setShowFPS(false);
			app.start();
		} catch (SlickException e) {
			e.printStackTrace();
		}

	}
}
