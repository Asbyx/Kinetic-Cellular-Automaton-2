import java.util.function.Supplier;

public abstract class Process { // Functions that takes inputs and outputs actions and a new complex State
  // todo: refactor such that there is a builder, otherwise the information layer needs the process and vice versa
  Information_layer i;
  public IntFunction<Integer> clock_map;
  
  public Process(){throw new IllegalStateException("No Information Layer Specified");};
  public Process(Information_layer i){this.i = i;}
  
  abstract void feedforward();
  abstract void act();
  abstract Integer get_new_complex_state();
  abstract Float get_target_length();
  void draw(float ui_w, float ui_h){text("Not implemented for this process.", width - ui_w - 50+10, height - ui_h - 50+32*3);}
}

public class NaiveVote_ClockMap_TLMap extends Process {
  /**
  This process is a simple voting system:
  each neighbor votes for its own complex_state and the most voted state becomes the new state of the cell.
  
  Caracteristics:
  ClockMap: we also add a vote for the internal clock of the cell (through a map that goes from clock_value -> complex_state).
  TLMap (Target Length Map): The target length of the links of going from the cell are set based on a map that goes from complex_state to an float
  
  Comments:
  This system has a major flaw: it encourages convergence of the states of an organism (several cells connected) without any reflexion behind it...
  */
  protected int[] votes;
  public IntFunction<Integer> clock_map;
  public IntFunction<Float> target_length_map;
  NaiveVote_ClockMap_TLMap(Information_layer i, IntFunction<Integer> clock_map, IntFunction<Float> target_length_map){super(i); this.clock_map = clock_map; this.target_length_map = target_length_map;}
  
  void feedforward() {
    votes = new int[complex_states_number];
    
    // all links
    for (Link l: i.c.ls){
      votes[l.get_other_complex_state(i.c)] ++;
    }
    
    // clock
    votes[clock_map.apply(i.clock_state)] += 1;
    votes[i.complex_state] += 1;
  }
  
  void act(){}
  
  // Return the most voted state, or the current state if there is draw
  Integer get_new_complex_state() {int m = 0, id = -1; for (int k = 0; k < complex_states_number; k++) if (votes[k] > m) {m = votes[k]; id = k;}; return votes[id] == votes[i.complex_state] ? i.complex_state : id;}
  Float get_target_length() {return target_length_map.apply(i.complex_state);}
}

public class Vote_ClockMap_TLMap_CSMap_VSMap extends NaiveVote_ClockMap_TLMap {
  /** 
  Simple voting system that we modify with two caracteristics:
  
  CSMap (Complex State Map): The complex state no longer votes for itself, but for CSmap(complex_state)
  VSMap (Voted State Map): The new state of the cell is now VSMap(voted_state), instead of directely the one voted.
  */ 
  public IntFunction<Integer> complex_state_map, voted_state_map;
  Vote_ClockMap_TLMap_CSMap_VSMap(Information_layer i, IntFunction<Integer> clock_map, IntFunction<Float> target_length_map, IntFunction<Integer> complex_state_map, IntFunction<Integer> voted_state_map) {super(i, clock_map, target_length_map); this.complex_state_map = complex_state_map; this.voted_state_map = voted_state_map;} 

  @Override
  void feedforward(){
    super.feedforward();
    // cancel the vote of the complex state and replace it with the map one
    votes[i.complex_state] -= 1; 
    votes[complex_state_map.apply(i.complex_state)] += 1;
  }
  
  @Override
  Integer get_new_complex_state() {Integer voted_state = super.get_new_complex_state(); return voted_state_map.apply(voted_state);}
}

public class Patterns_Voting extends Process {
  /**
  This process consists of having patterns of complex states that vote for a specific complex state.
  Then, the most voted complex state is chosen.

  CSMap and ClockMap are not used here, as the voting is done based on the patterns, which already specify the voted states.
  TLMap is used to set the target length of the links.
  */
  protected int[] complex_states = new int[complex_states_number];
  protected Pattern[] patterns;
  protected int[] votes = new int[complex_states_number];
  protected boolean include_own_cs;
  protected IntFunction<Float> target_length_map;
  
  Patterns_Voting(Information_layer i, Pattern[] patterns, boolean include_own_cs, IntFunction<Float> target_length_map){super(i); this.patterns = patterns; this.include_own_cs = include_own_cs; this.target_length_map = target_length_map;}

  void feedforward(){
    votes = new int[complex_states_number];
    complex_states = new int[complex_states_number];

    for (Link l: i.c.ls) complex_states[l.get_other_complex_state(i.c)] ++;
    if (include_own_cs) complex_states[i.complex_state] ++;
    for (Pattern p: patterns) if (p.verify(complex_states)) votes[p.voted_state] ++;
  }

  void act(){}

  /**
  Return the most voted state, or the current state if there is draw
  */
  Integer get_new_complex_state() {int m = 0, id = 0; for (int k = 0; k < complex_states_number; k++) if (votes[k] > m) {m = votes[k]; id = k;}; return votes[id] == votes[i.complex_state] ? i.complex_state : id;}
  Float get_target_length() {return target_length_map.apply(i.complex_state);}

  void draw(float ui_w, float ui_h){ // fixme: we would like the next voted state, not current
    float baseX = width - ui_w - 50+10, baseY = height - ui_h - 50+32*3;
    
    // Input
    text("Complex States:", baseX, baseY);
    float x = baseX + textWidth("Complex States:   ");
    for (int k = 0; k < complex_states_number; k++) {
      fill(state_color(k)); rect(x, baseY - 14, 14, 14); colorMode(RGB, 255); fill(255, 255, 255, 155); 
      text(": " + complex_states[k], x + 20, baseY);
      x += 40;
    }

    // Patterns
    baseY += 32;
    text("Patterns:", baseX, baseY);
    for (Pattern p: patterns) {float[] dim = p.draw(baseX + textWidth("Patterns: "), baseY); baseY += dim[1];}

    // Draw the selected state with rect
    baseY += 64;
    text("Selected State: " + get_new_complex_state(), baseX, baseY);
    fill(state_color(get_new_complex_state())); rect(baseX + textWidth("Selected State: "), baseY - 14, 14, 14); colorMode(RGB, 255); fill(255, 255, 255, 155);    
  }
}
public class Pattern {
    /** 
    Map that goes from complex states to an upper and a lower bound of the number of representatives of this complex state in the neighborhood
    The pattern is verified if the number of representatives of each complex state in the map is in the bounds. Complex states not in the map are ignored. 
    */
    public HashMap<Integer, int[]> map;
    public int voted_state;
    public Pattern(HashMap<Integer, int[]> map, int voted_state){this.map = map; this.voted_state = voted_state;}

    public boolean verify(int[] complex_states){
      for (int k: map.keySet()){
        int[] bounds = map.get(k);
        if (complex_states[k] < bounds[0] || complex_states[k] > bounds[1]) return false;
      }
      return true; // all conditions are met
    }

    /**
    Return the max state used, i.e the threshold for the number of complex states for which the pattern is usable
    For example, if number_complex_states = 2 and this function returns 4, the pattern is unusable. 
    */
    public int max_state(){
      return max(voted_state, map.keySet().stream().max((a, b) -> a - b).get());
    }
    
    /**
    Draw the pattern
    Return the width and height of the drawing
    */
    public float[] draw(float x, float y){
      float baseX = x, baseY = y;
      text("Vote for", baseX, baseY);
      fill(state_color(voted_state)); rect(baseX + textWidth("Vote for "), baseY - 14, 14, 14); colorMode(RGB, 255); fill(255, 255, 255, 155);
      for (int j: map.keySet()) {
        int[] bounds = map.get(j);
        fill(state_color(j)); rect(baseX, baseY + 19, 14, 14); colorMode(RGB, 255); fill(255, 255, 255, 155);
        text(": [" + bounds[0] + ", " + bounds[1] + "]", baseX + 20, baseY += 32);
      }
      return new float[]{textWidth("Vote for ") + 20 + 14, 32 * (1 + map.size())};
    }
}
