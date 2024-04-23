import java.util.function.IntFunction;
import java.util.function.Function;
import java.util.Objects;
import java.util.HashSet;

// constants
World world;
boolean is_showing_ls = true;
boolean is_recording = false;
boolean is_stepping = true, step = false;  //'s' to toggle, space to make a step



// parameters of the model
// physic layer
int num_c = 50; // Warning: cannot be above 9999, risk of unstability due to the using of a hashset for the collection of links, with custom hashCode function
float link_strength = 0.0015;  
float friction_cst = 0.005; // only useful to avoid kinetic explosions, the model can work without it. Value must be between 0 and 1, 0 meaning no friction

// information layer
int clock_period = 90; // Period of the internal clock of the cells
int complex_states_number = 2; // Number of complex states in the cells

// test for circuits
IntFunction<Integer> clock_map = c -> 1;//c/45; // ground
IntFunction<Float> TLMap = c -> 50.0; // we don't care
Function<Information_layer, Process> universal_process = i -> new NaiveVote_ClockMap_TLMap(i, clock_map, TLMap);

// utils functions
void init_world() {
    /*TEMP: for random init:
    for (int k = 0; k < num_c; k++) world.cs.add(new C(random(width), random(height), new Information_layer(int(random(complex_states_number)), universal_process)));  
    
    // TEMP: hard coding the creation of links
    for (int k = 0; k < num_c/3; k++) world.attach(world.cs.get(int(random(world.cs.size()))), world.cs.get(int(random(world.cs.size()))));
    */
    world.cs.add(new C(250, 225, new Information_layer(1, universal_process)));
    world.cs.add(new C(250, 275, new Information_layer(1, universal_process)));
    
    world.cs.add(new C(300, 250, new Information_layer(0, universal_process)));
    
    world.attach(world.cs.get(0), world.cs.get(2));
    world.attach(world.cs.get(1), world.cs.get(2));
}

Integer state_color(int a){colorMode(HSB, complex_states_number); return color(a, 255, 255);}


// all classes
class Information_layer { // Information layer of a C
  C c = null; // original cell
  Integer clock_state = int(random(clock_period)), prev_complex_state, complex_state; // clock_state is self explanatory, complex_state is the actual internal state of the clock
  Process process;
  
  Information_layer(Integer complex_state, Function<Information_layer, Process> process_builder){this.complex_state = complex_state; this.prev_complex_state = complex_state; this.process = process_builder.apply(this);} 
  Information_layer set_c(C c){this.c = c; return this;}
  
  void evo(){
    assert c != null;
    clock_state += 1; clock_state %= clock_period; // clock
    prev_complex_state = complex_state;
    
    process.feedforward(); process.act(); complex_state = process.get_new_complex_state();
  }
}



class C { // Physical layer for the cell (or chemical element)
    float x, y, vx, vy = 0;
    HashSet<Link> ls = new HashSet<Link>(); // all links starting from the C
    
    Information_layer i;
   
    C (float x, float y, Information_layer i) {this.x = x; this.y = y; this.i = i.set_c(this);}
    C (float x, float y, Information_layer i, float vx, float vy) {this(x, y, i); this.vx = vx; this.vy = vy;}
    
    void evo() { 
      // Physical interactions
      x += vx; y += vy; if (x <= 0 || x >= world.w) vx *= -1; if (y <= 0 || y >= world.h) vy *= -1; 
      // default friction   
      vx *= 1 - friction_cst; vy *= 1 - friction_cst;
      
      i.evo();
    }
    void draw(){fill(state_color(((NaiveVote_ClockMap_TLMap)i.process).clock_map.apply(i.clock_state))); ellipse(x, y, 11, 18); fill(state_color(i.complex_state)); ellipse(x, y, 10, 10);}
    
    // utils function and classes
    float dist_to(C c) { return sqrt(sq(x - c.x) + sq(y - c.y));}
}

class Link { // Link between two cells, that makes the bridge between the physical and the information layers. Physically acts like a spring, Informatively acts like a communication channel
   C c1, c2;
   int hashcode; // 8 digits: 4 for index of c1 in world and 4 for c2 in world, sorted. Example: c1 and c2 are indexed 524 and 23 resp., hashcode of the link: 00230524
   boolean force_compression = false;

   Link(C c1, C c2) { this.c1 = c1; this.c2 = c2; this.hashcode = Integer.parseInt(String.format("%04d", min(world.cs.indexOf(c1), world.cs.indexOf(c2)))+String.format("%04d", max(world.cs.indexOf(c1), world.cs.indexOf(c2))));}
   
   void evo() {
     float d = c1.dist_to(c2); if (d == 0) return; 
     float ref_len = c1.i.process.get_target_length(); if (force_compression) ref_len = 20;
     float dx = c2.x - c1.x, dy = c2.y - c1.y, ndx = dx / d, ndy = dy / d, diff_len = d - ref_len;
     float fx = diff_len * ndx * link_strength, fy = diff_len * ndy * link_strength; 
     c1.vx += fx; c1.vy += fy; c2.vx -= fx; c2.vy -= fy;
   } 
   
   int get_other_complex_state(C c){
     C other = c == c1 ? c2 : c1;
     return other.i.prev_complex_state; // We take the previous state
   }
   
   //todo: indiquer la direction
   void draw() {stroke(5, 0, 2); strokeWeight(1); line(c1.x, c1.y, c2.x, c2.y); }
   
   void toggle_force_compression(){force_compression = !force_compression;}
   
   @Override
   boolean equals(Object other){return other instanceof Link && ((c1 == ((Link) other).c1 && c2 == ((Link) other).c2) || (c1 == ((Link) other).c2 && c2 == ((Link) other).c1));}
   @Override
   int hashCode(){return hashcode;}
}

class World { // Physical world: contains the C and the Links and handle the physical interactions
   int w, h;
   ArrayList<C> cs = new ArrayList<C>();
   HashSet<Link> ls = new HashSet<Link>(); // It is necessary to have it there in order to simplify the physical interactions generated by the links
   
   World (int w, int h) { this.w = w; this.h = h; }
 
   // Function meant to be called by a cell that wants to be attached to another
   void attach(C c1, C c2) {if (c1 == c2) return; Link l = new Link(c1, c2); ls.add(l); c1.ls.add(l);}
 
   void evo() {for (Link l : ls) l.evo(); for (C c : cs) c.evo();}
   void draw() {for (C c : cs) c.draw(); if(is_showing_ls) for (Link l : ls) l.draw();}
}


/*------------------------------------------------------------------------------------------*/
void setup(){fullScreen(); world = new World(width, height); init_world();}

void draw() {background(0); if(!is_stepping || step) {world.evo(); step = false;} world.draw(); colorMode(RGB, 255); textSize(50); fill(255); text(world.cs.stream().map(c->c.x).reduce(0.0, Float::sum), 100, 100);}

void keyPressed(){
  if (key == 's') {is_stepping = !is_stepping; step = false;} 
  if (key == ' ') {step = true;}
  
  // cheat keys
  if (key == 'a') {world.ls.iterator().next().toggle_force_compression();}
  if (key == 'v') {world.cs.get(0).vx = 2;}
}
