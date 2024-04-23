import java.util.function.Supplier;

public abstract class Process { // Functions that takes inputs and outputs actions and a new complex State
  Information_layer i;
  public IntFunction<Integer> clock_map;
  
  public Process(){throw new IllegalStateException("No Information Layer Specified");};
  public Process(Information_layer i){this.i = i;}
  
  abstract void feedforward();
  abstract void act();
  abstract Integer get_new_complex_state();
  abstract Float get_target_length();
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
