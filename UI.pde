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

interface UI_Block {
  public boolean is_active = false; // if this block is in current use (ex: currently creating a link)
  public boolean is_exclusive = false; // if this block should be alone when used. Like changing the state of a cell cannot be done while constructing a new link. Set false for statistical UI elements or so.
  
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
}
