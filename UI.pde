import java.util.Arrays;

class UI {
  private boolean is_active = true;
  private UI_Block[] blocks; 
  final int description_size = 16;
  
  private int bg_width = width/7, bg_height, bg_x = width - bg_width - 20, bg_y = 20;
  
  UI(UI_Block[] blocks){this.blocks = blocks; bg_height = 25 + (Arrays.stream(blocks).mapToInt(b -> b.description().length).sum()+1)*description_size;}
  
  void on_key_pressed(){for (UI_Block b : blocks) b.on_key_pressed();}
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
  
  String[] description() {
    return new String[] {"A - Add a cell"};
  }
  
  void on_key_pressed() {
    if (key == 'a') {is_active = !is_active;} 
    if (!is_active) return;
    
    if (key == 's') {state += 1; state %= complex_states_number;}    
    if (key == 'c') {clock += 1; clock %= clock_period;}
  }
  
  // add the C at the coordinates of the mouse
  void on_mouse_pressed() { if (!is_active) return; world.cs.add(new C(mouseX, mouseY, new Information_layer(state, universal_process).set_clock_state(clock))); is_active = false;}
  
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

