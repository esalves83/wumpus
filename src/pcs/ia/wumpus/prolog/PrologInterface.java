/*
 * Classname             PrologInterface
 * 
 * Interface entre o núcleo Prolog e Java
 * Responsável por executar cada passo do agente
 * Executa consultas à base de conhecimento e mostra resultados em uma janela gráfica
 */

package pcs.ia.wumpus.prolog;

import java.util.HashMap;
import java.util.Map;

import org.jpl7.Atom;
import org.jpl7.Compound;
import org.jpl7.Query;
import org.jpl7.Term;
import org.jpl7.Variable;

import pcs.ia.wumpus.player.Player;
import pcs.ia.wumpus.util.Pose2D;
import pcs.ia.wumpus.util.Constants.ObjectType;
import pcs.ia.wumpus.util.Constants.PlayerActionDir;

import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.Multimap;

public class PrologInterface {
	
	Query query;
    
	/**
	 * Carrega a base de conhecimento wumpus.pl
	 * Inicializa o mapa e os atributos do agente
	 */
	public PrologInterface() {
		// TODO Auto-generated constructor stub
		query = new Query("consult", new Term[] { new Atom("data/wumpus.pl") });
		query.hasSolution();
		
		query = new Query("initialize_general");
		query.hasSolution();
	}
	
	/**
	 * Query para retomar as configurações iniciais do agente a qualquer momento do jogo
	 */
	public static void prologRestart(){
		Query restart = new Query("initialize_general");
		restart.hasSolution();
	}
	
	/**
	 * Executa um passo do Prolog e atualiza os atributos do agente no Java
	 */
	public static void oneStep(Player player){
		
		// Algumas variáveis locais
		int x,y,x_prolog,y_prolog;
		int delta = 170;		
		Map<String, Term> one_solution = new HashMap<String, Term>();
		
		Query step = new Query("step");
		step.hasSolution();
		
		// Recupera localização do agente do núcleo Prolog
		Query aloc = new Query(new Compound("agent_location", new Term[] { new Variable("AL")}));
		Term[] t_agent = aloc.oneSolution().get("AL").toTermArray();
		
		// Conversão de dados para o mapa gráfico
		// [1,1] Prolog = [68,592] Mapa gráfico
		x_prolog = t_agent[0].intValue();			 // No Prolog: 0 < [x,y] < 5
		y_prolog = t_agent[1].intValue();
		x = 68 + ((t_agent[0].intValue()-1)*delta);  // No mapa gráfico 68 < x < 748
		y = 592 - ((t_agent[1].intValue()-1)*delta); // 88 < y < 592
		
		// Só permite a movimentação do jogador caso a futura posição não seja uma parede
		// Caso contrário, o desenho do agente some da tela
		if (!(isBlocked(x_prolog, y_prolog))){
			Pose2D agent_pos = new Pose2D(x,y);
			player.setPlayerPose2D(agent_pos);
			
			Pose2D pose_prolog = new Pose2D(x_prolog,y_prolog);
			player.setPlayerPose2DProlog(pose_prolog);
		}
		
		// Recupera orientação do agente no núcleo Prolog
		Query aori = new Query(new Compound("degree", new Term[] { new Variable("O")}));
		one_solution = aori.oneSolution();
		
		// Atualiza desenho da orientação do agente
		switch(one_solution.get("O").toString()){
		case "east":
			player.setPlayerActionDir(PlayerActionDir.RIGHT);
			break;
		case "west":
			player.setPlayerActionDir(PlayerActionDir.LEFT);
			break;
		case "north":
			player.setPlayerActionDir(PlayerActionDir.UP);
			break;
		case "south":
			player.setPlayerActionDir(PlayerActionDir.DOWN);
			break;
		}
		
		// Recupera percepções do agente no Prolog
		Query stenchy = new Query(new Compound("stenchy", new Term[] { new Variable("S")}));
		one_solution = stenchy.oneSolution();
		
		if(one_solution.get("S").toString().equals("yes"))
			player.setStench(true);		// Fedor = sim
		else
			player.setStench(false);	// Fedor = não
		
		Query breeze = new Query(new Compound("bleezy", new Term[] { new Variable("B")}));
		one_solution = breeze.oneSolution();
		if(one_solution.get("B").toString().equals("yes"))
			player.setBreeze(true);		// Brisa = sim
		else
			player.setBreeze(false);	// Brisa = não
		
		Query glitter = new Query(new Compound("glittering", new Term[] { new Variable("G")}));
		one_solution = glitter.oneSolution();
		if(one_solution.get("G").toString().equals("yes"))
			player.setGlitter(true);	// Brilho = sim
		else
			player.setGlitter(false);	// Brilho = não
		
		Query bump = new Query(new Compound("bumped", new Term[] { new Variable("BU")}));
		one_solution = bump.oneSolution();
		if(one_solution.get("BU").toString().equals("yes"))
			player.setBump(true);		// bateu_na_parede = sim
		else
			player.setBump(false);		// bateu_na_parede = não
		
		Query scream = new Query(new Compound("heardscream", new Term[] { new Variable("HS")}));
		one_solution = scream.oneSolution();
		if(one_solution.get("HS").toString().equals("yes"))
			player.setScream(true);		// grito_do_wumpus = sim
		else
			player.setScream(false);	// grito_do_wumpus = não
		
		// Recupera o objetivo atual do agente
		Query short_goal = new Query(new Compound("short_goal", new Term[] { new Variable("SG")}));
		one_solution = short_goal.oneSolution();
		player.setPlayerShortGoal(one_solution.get("SG").toString());
		
		// Consulta a saúde do Wumpus (vivo/morto)
		Query wumpus_healthy = new Query("is_dead");
		player.setkilledWumpus(wumpus_healthy.hasSolution());
		
		// Consulta se agente está na caverna
		Query agent_in_cave = new Query("agent_in_cave");
		player.setAgentInCave(agent_in_cave.hasSolution());
		
		// Consulta se agente está segurando ouro
		Query agent_hold = new Query("agent_hold");
		player.setFoundGold(agent_hold.hasSolution());
		
		// Recupera pontuação do agente
		Query agent_score = new Query(new Compound("agent_score", new Term[] { new Variable("AS")}));
		one_solution = agent_score.oneSolution();
		player.setPlayerScore(one_solution.get("AS").intValue());
		
		// Recupera número do passo
		Query step_number = new Query(new Compound("time", new Term[] { new Variable("T")}));
		one_solution = step_number.oneSolution();
		player.setPlayerStepNumber(one_solution.get("T").intValue());
		
		// Recupera número de salas visitadas
		Query nVisited = new Query(new Compound("nb_visited", new Term[] { new Variable("V")}));
		one_solution = nVisited.oneSolution();
		player.setPlayerPosesVisited(one_solution.get("V").intValue());
		
		// Recupera objetivo atual do agente
		Query agent_goal = new Query(new Compound("agent_goal", new Term[] { new Variable("AG")}));
		one_solution = agent_goal.oneSolution();
		player.setPlayerAgentGoal(one_solution.get("AG").toString());
	}
	
	/**
	 * Consulta a posição dos objetos (Wumpus, poços e ouro) no mundo
	 */
	public static Multimap<ObjectType, Pose2D> consultObjects(){
		
		Multimap<ObjectType, Pose2D> ret = ArrayListMultimap.create();		
		Map<String, Term> one_solution = new HashMap<String, Term>();
		
		Pose2D wumpus_pos = new Pose2D(0,0);
		Pose2D gold_pos = new Pose2D(0,0);
		
		// Posição do ouro
		Query gold = new Query(new Compound("gold_location", new Term[] { new Variable("X")}));
		Term[] t_gold = gold.oneSolution().get("X").toTermArray();
		gold_pos.setX(t_gold[0].intValue());
		gold_pos.setY(t_gold[1].intValue());
		ret.put(ObjectType.GOLD, gold_pos);
		
		// Posição do Wumpus
		Query wumpus = new Query(new Compound("wumpus_location", new Term[] { new Variable("X")}));
		Term[] t_wumpus = wumpus.oneSolution().get("X").toTermArray();
		wumpus_pos.setX(t_wumpus[0].intValue());
		wumpus_pos.setY(t_wumpus[1].intValue());
		ret.put(ObjectType.WUMPUS, wumpus_pos);
		
		// Posições dos poços
		Query pit = new Query(new Compound("pit_location", new Term[] { new Variable("X")}));
		while ( pit.hasMoreSolutions() ){
			one_solution = pit.nextSolution();
			Term[] t_pit = one_solution.get("X").toTermArray();
			Pose2D pit_pos = new Pose2D(t_pit[0].intValue(),t_pit[1].intValue());
			ret.put(ObjectType.PIT, pit_pos);
		}		
		return ret;		
	}
	
	/**
	 * Verifica se a posição Prolog não ultrapassa o máximo tamanho do tabuleiro
	 */
	private static boolean isBlocked(int x, int y) {
		
		if((x>0 && x<5) && (y>0 && y<5))
			return false;
		else
			return true;
	}
}
