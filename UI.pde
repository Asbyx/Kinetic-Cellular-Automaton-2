import java.util.Arrays;

class UI {
  private boolean is_active = true;
  private UI_Block[] blocks; 
  final int description_size = 16;
  
  private int bg_width = width/7, bg_height, bg_x = width - bg_width - 20, bg_y = 20;
  
  UI(UI_Block[] blocks){this.blocks = blocks; bg_height = 25 + (Arrays.stream(blocks).mapToInt(b -> b.description().length).sum()+1)*description_size;}
  
  void on_key_pressed(){
    boolean exclusive_active = Arrays.stream(blocks).anyMatch(b -> b.is_active() && b.is_exclusive());
    if (!exclusive_active) Arrays.stream(blocks).forEach(UI_Block::on_key_pressed); 
    else Arrays.stream(blocks).filter(b -> !b.is_exclusive() || b.is_active()).forEach(UI_Block::on_key_pressed); 
  }
  void on_mouse_pressed(){for (UI_Block b : blocks) b.on_mouse_pressed();}
  
  void toggle() {is_active = !is_active;}
  
  void draw(){ if (!is_active) return;
    draw_background();
    draw_blocks_documentation();
    Arrays.stream(blocks).forEach(UI_Block::draw);
  }
  
  private void draw_background(){
    fill(255, 255, 255, 75);
    rect(bg_x, bg_y, bg_width, bg_height);
    fill(255, 255, 255, 175);
    textSize(25);
    text("Commands", bg_x + 5, bg_y + 25);
  }
  
  private void draw_blocks_documentation(){
    textSize(description_size);
    int cursor_y = bg_y + 25;
    for(UI_Block b : blocks) {
      for (String s: b.description()) {text(s, bg_x+5, bg_y + cursor_y); cursor_y += description_size;}
    }
  }
}

// UI elements, that acts on the simulation or just visual elements
interface UI_Block {
  default boolean is_active() {return false;} // if this block is in current use (ex: currently creating a link)
  default boolean is_exclusive() {return false;} // if this block should be alone when used. Like changing the state of a cell cannot be done while constructing a new link. Set false for statistical UI elements or so.
  
  String[] description(); // short documentation of the block
  void on_key_pressed();
  void on_mouse_pressed();
  void draw();
}



class Pause_And_Step implements UI_Block {
  String[] description(){
    return new String[] {"P - Pause the simulation", "Space - While paused, make a step"};
  }
  
  void on_key_pressed(){
    if (key == 'p') {is_paused = !is_paused; step = false;} 
    if (key == ' ') {step = true;}
  }
  
  void on_mouse_pressed(){}
  void draw(){if (is_paused) {textSize(32); text("Simulation Paused", 32, 32);}}  
}

class Add_C implements UI_Block {
  private int ui_w = width / 2, ui_h = 100;
  
  private int state = 0;
  private int clock = 0;
  
  private boolean is_active = false;
  @Override
  boolean is_active() {return is_active;}
  @Override
  boolean is_exclusive() {return true;}
  
  String[] description() {
    return new String[] {"A - Add a cell"};
  }
  
  void on_key_pressed() {
    if (key == 'a') {is_active = !is_active;} 
    if (!is_active) return;
    
    if (key == 's') {state += 1; state %= complex_states_number;}    
    if (key == 'c') {clock += 1; clock %= clock_period;}
    if (key == 'r') {state = (int) random(complex_states_number); clock = (int) random(clock_period); add_c(random(width), random(height));} // add a random C
  }
  
  // add the C at the coordinates of the mouse
  void on_mouse_pressed() { if (!is_active) return; add_c(mouseX, mouseY);}
  
  void add_c(float x, float y) {world.cs.add(new C(x, y, new Information_layer(state, universal_process).set_clock_state(clock))); is_active = false;}

  void draw() {if (!is_active) return;
    // rectangle and title
    fill(255, 255, 255, 75);
    rect(50, height - ui_h - 50, ui_w, ui_h);
    fill(255, 255, 255, 155);
    textSize(25);
    text("Click somewhere to add this C, or press A to cancel.", 50+10, height - ui_h - 50+32);
    
    // state selection
    textSize(16);
    String string = "Press S to switch state. Current state of the new cell: ";
    text(string, 50+10, height - ui_h - 50+32+30); fill(state_color(state)); rect(50+10+10+textWidth(string), height - ui_h - 50+32+16, 16, 16); colorMode(RGB, 255);

    // clock selection
    fill(255, 255, 255, 155);
    text("Press C to switch clock. Current clock value of the new cell: " + clock, 50+10, height - ui_h - 50+32+30*2);
  }  
}

class Modify_C implements UI_Block {
  private int ui_w = width / 2, ui_h = 75;
  private C c;
  private boolean dragging = true;
  
  private boolean is_active = false;
  @Override
  boolean is_active() {return is_active;}
  @Override
  boolean is_exclusive() {return true;}
  
  String[] description() {
    return new String[] {"M - Modify a cell"};
  }
  
  void on_key_pressed() {
    if (key == 'm') {is_active = !is_active; c = world.cs.get(0);} 
    if (!is_active) return;
    
    if (key == 's') {c.i.complex_state += 1; c.i.complex_state %= complex_states_number;}    
    if (key == 'c') {c.i.clock_state += 1; c.i.clock_state %= clock_period;}
  }
  
  void on_mouse_pressed() {
    if (!is_active) return;
    C c_ = world.cs.stream().min((c1, c2) -> Float.compare(dist(c1.x, c1.y, mouseX, mouseY), dist(c2.x, c2.y, mouseX, mouseY))).get();
    if (c_ == c && dist(c.x, c.y, mouseX, mouseY) < 20)  {dragging = true;} else {c = c_;}
  }
  
  void draw() {if (!is_active) return;
    // rectangle and title
    fill(255, 255, 255, 75);
    rect(50, height - ui_h - 50, ui_w, ui_h);
    fill(255, 255, 255, 155);
    textSize(25);
    text("Click on a C to select it. S to change its state, C to increase its clock value. \nDrag the C to move it. M to exit.", 50+10, height - ui_h - 50+32);

    // Write the clock value below the selected C
    fill(255, 255, 255, 155); 
    textSize(16);
    text("Current clock value: " + c.i.clock_state, c.x - textWidth("Current clock value: 00")/2, c.y + 20);

    if (dragging && mousePressed) {c.x = mouseX; c.y = mouseY;} else dragging = false;
  }
}

class Remove_C implements UI_Block {
  private int ui_w = width / 2, ui_h = 50;
  private C c;
  
  private boolean is_active = false;
  @Override
  boolean is_active() {return is_active;}
  @Override
  boolean is_exclusive() {return true;}

  String[] description() {
    return new String[] {"R - Remove a cell"};
  }
  
  void on_key_pressed() {
    if (key == 'r') {is_active = !is_active; c = world.cs.get(0);} 
    if (!is_active) return;
    
    if (key == ENTER) {world.remove(c); is_active = false;}
  }
  
  void on_mouse_pressed() {
    if (!is_active) return;
    c = world.cs.stream().min((c1, c2) -> Float.compare(dist(c1.x, c1.y, mouseX, mouseY), dist(c2.x, c2.y, mouseX, mouseY))).get();
  }
  
  void draw() {if (!is_active) return;
    // rectangle and title
    fill(255, 255, 255, 75);
    rect(50, height - ui_h - 50, ui_w, ui_h);
    fill(255, 255, 255, 155);
    textSize(25);
    text("Click on a C to select it. Press enter to remove it, or R to cancel", 50+10, height - ui_h - 50+32);

    // Indicate the selected C
    fill(255, 255, 255, 155); textSize(16); text("Selected C", c.x - textWidth("Selected C")/2, c.y + 20);
  }
}

class Add_Link implements UI_Block {
  private int ui_w = width / 2, ui_h = 50;
  private C c1, c2;
  private boolean selecting_c1 = true;
  
  private boolean is_active = false;
  @Override
  boolean is_active() {return is_active;}
  @Override
  boolean is_exclusive() {return true;}

  String[] description() {
    return new String[] {"L - Add a link"};
  }
  
  void on_key_pressed() {
    if (key == 'l') {is_active = !is_active; c1 = c2 = null; selecting_c1 = true;} 
    if (!is_active) return;
    
    if (key == ENTER) {if (c1 != null && c2 != null) {world.attach(c1, c2); is_active = false;}} 
    if (key == 'r') {while(!world.attach(world.cs.get((int)random(world.cs.size())), world.cs.get((int)random(world.cs.size()))));} // add a random link
  }
  
  void on_mouse_pressed() {
    if (!is_active) return;
    C closest = world.cs.stream().min((c1, c2) -> Float.compare(dist(c1.x, c1.y, mouseX, mouseY), dist(c2.x, c2.y, mouseX, mouseY))).get();
    if (selecting_c1) {c1 = closest; selecting_c1 = false;} else {c2 = closest; selecting_c1 = true;}
  }
  
  void draw() {if (!is_active) return;
    // rectangle and title
    fill(255, 255, 255, 75);
    rect(50, height - ui_h - 50, ui_w, ui_h);
    fill(255, 255, 255, 155);
    textSize(25);
    text("Click on a C to select it. Press enter to create the link, or L to cancel", 50+10, height - ui_h - 50+32);

    // first cell
    if (c1 != null) {fill(255, 255, 255, 155); textSize(16); text("c1", c1.x, c1.y + 20);}

    // second cell
    if (c2 != null) {fill(255, 255, 255, 155); textSize(16); text("c2", c2.x, c2.y + 20);}
  }
}

class Remove_Link implements UI_Block {
  private int ui_w = width / 2, ui_h = 50;
  private Link l;
  
  private boolean is_active = false;
  @Override
  boolean is_active() {return is_active;}
  @Override
  boolean is_exclusive() {return true;}

  String[] description() {
    return new String[] {"D - Remove a link"};
  }
  
  void on_key_pressed() {
    if (key == 'd') {is_active = !is_active; l = world.ls.iterator().next();} 
    if (!is_active) return;
    
    if (key == ENTER) {world.remove(l); is_active = false;}
  }
  
  void on_mouse_pressed() {
    if (!is_active) return;
    // select the link closest which has its center closest to the mouse
    l = world.ls.stream().min((l1, l2) -> Float.compare(dist((l1.c1.x + l1.c2.x)/2, (l1.c1.y + l1.c2.y)/2, mouseX, mouseY), dist((l2.c1.x + l2.c2.x)/2, (l2.c1.y + l2.c2.y)/2, mouseX, mouseY))).get();
  }

  void draw() {if (!is_active) return;
    // rectangle and title
    fill(255, 255, 255, 75);
    rect(50, height - ui_h - 50, ui_w, ui_h);
    fill(255, 255, 255, 155);
    textSize(25);
    text("Click on a link to select it. Press enter to remove it, or D to cancel", 50+10, height - ui_h - 50+32);

    // Indicate the selected link
    fill(255, 255, 255, 155); textSize(16); text("Selected Link", (l.c1.x + l.c2.x)/2 - textWidth("Selected Link")/2, (l.c1.y + l.c2.y)/2);
  }
}

//fixme ?
class Visualize_Process implements UI_Block {
  private int ui_w = width / 4, ui_h = width / 3;
  private C c;
  
  private boolean is_active = false;
  @Override
  boolean is_active() {return is_active;}
  @Override
  boolean is_exclusive() {return false;}

  String[] description() {
    return new String[] {"V - Visualize the process of a C"};
  }
  
  void on_key_pressed() {
    if (key == 'v') {is_active = !is_active; c = world.cs.get(0);} 
    if (!is_active) return;
  }
  
  void on_mouse_pressed() {
    if (!is_active) return;
    c = world.cs.stream().min((c1, c2) -> Float.compare(dist(c1.x, c1.y, mouseX, mouseY), dist(c2.x, c2.y, mouseX, mouseY))).get();
  }

  void draw() {if (!is_active) return;
    // rectangle and title
    fill(255, 255, 255, 75);
    rect(width - ui_w - 50, height - ui_h - 50, ui_w, ui_h);
    fill(255, 255, 255, 155);
    textSize(25);
    text("Click on a C to select it. \nPress V to visualize its process, or V to cancel.", width - ui_w - 50+10, height - ui_h - 50+32);

    // Indicate the selected C
    fill(255, 255, 255, 155); textSize(16); text("Selected C", c.x - textWidth("Selected C")/2, c.y + 20);

    // Draw the process
    c.i.process.draw(ui_w, ui_h);    
  }
}

/*
Open a small window in the center of the screen where you can build a new pattern
The voted state is selected through passing through the states with the s key, then the bounds are selected by arrow keys 
*/
class Pattern_Builder implements UI_Block {
  private int ui_w = width / 2, ui_h = 200;
  private Pattern pattern;
  public HashMap<Integer, int[]> map;
  public int voted_state;
  private int[] bound_selector; // 0: state, 1: {0: state watched, 1: bound 1, 2: bound 2}

  private boolean is_active = false;
  @Override
  boolean is_active() {return is_active;}
  @Override
  boolean is_exclusive() {return true;}

  String[] description() {
    return new String[] {"B - Build a pattern"};
  }

  private int find_next_key(int key, boolean forward, boolean occupied) {
    int next_key = key + (forward ? 1 : -1);
    while (next_key != key) {
      if (map.containsKey(next_key) == occupied) return next_key;
      
      next_key += forward ? 1 : -1;
      if (next_key < 0) next_key = complex_states_number - 1;
      if (next_key >= complex_states_number) next_key = 0;
    }
    return key;
  }
  
  void on_key_pressed() {
    if (key == 'b') {is_active = !is_active; bound_selector = new int[]{0, 0}; map = new HashMap(); voted_state = 0; map.put(0, new int[]{0, 0});}
    if (!is_active) return;
    
    if (key == 's') {voted_state += 1; voted_state %= complex_states_number;}

    if (key == '+') {
      //find the first unused key
      int first_not_used = find_next_key(bound_selector[0], true, false);
      if (first_not_used == bound_selector[0]) return;
       
      map.put(first_not_used, new int[]{0, 0});
    }
    
    if (keyCode == UP) {
      if (bound_selector[1] == 0) {
        // transfer the bounds to the next unused key
        int first_not_used = find_next_key(bound_selector[0], true, false);
        if (first_not_used == bound_selector[0]) return;
        
        map.put(first_not_used, map.get(bound_selector[0]));
        map.remove(bound_selector[0]);
        bound_selector[0] = first_not_used;
      } 
      else {map.get(bound_selector[0])[bound_selector[1]-1] += 1;}}
    if (keyCode == DOWN) {if (bound_selector[1] != 0) {map.get(bound_selector[0])[bound_selector[1]-1] -= 1;}}
    
    if (keyCode == LEFT) {
      if (bound_selector[1] == 0) {
        bound_selector[1] = 2; 
        bound_selector[0] = find_next_key(bound_selector[0], false, true); 
        } else bound_selector[1] -= 1;}
    
    if (keyCode == RIGHT) {
      if (bound_selector[1] == 2) {
        bound_selector[1] = 0; 
        bound_selector[0] = find_next_key(bound_selector[0], true, true);
        } else bound_selector[1] += 1;}
    if (key == ENTER) {} //todo; is_active = false;
    pattern = new Pattern(map, voted_state);
  }
  
  void on_mouse_pressed() {}

  void draw() {if (!is_active) return;
    // rectangle and title
    fill(255, 255, 255, 75);
    rect(width/2 - ui_w/2, height/2, ui_w, ui_h);
    fill(255, 255, 255, 155);
    textSize(25);
    text("Press S to switch voted state. Use arrow keys to change the patterns. Press + to add bounds\nPress enter to save the pattern, or B to cancel.", width/2 - ui_w/2+10, height/2+32);

    ui_h = 75 + int(pattern.draw(width/4 + 10, height/2 + 64+32)[1]);

    // draw a line for the bound selector
    fill(255, 255, 255, 155);
    
    // get the index of the bound selector 0 in the keys of the map
    int index = 0; for (int i : map.keySet()) {if (i == bound_selector[0]) break; index += 1;}

    // draw the line under the selected bound
    float x = 0, y = height/2 + 64+32+32+5 + 32*index;
    switch(bound_selector[1]) {
      case 0: x = width/4 + 7; break;
      case 1: x = width/4 + 14 + textWidth(" : [ "); break;
      case 2: x = width/4 + 14 + textWidth(" : [ " + pattern.map.get(bound_selector[0])[0] +", "); break;
    }
    rect(x, y, 20, 3);
  }
}