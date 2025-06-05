`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/10 19:31:53
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module main(
    clk, rst_pos, S0, S1, S2, S3, S4, level,
    ps2_clk, Keyboard_Data,
    hsync, vsync, vga_r, vga_g, vga_b, 
    Enable_left, Enable_right, Seven_Seg_left, Seven_Seg_right, led
    );
    
    input           clk;
    input           rst_pos;
    input           S0,S1,S2,S3,S4;
    input           level;
    input           ps2_clk, Keyboard_Data;
   
    output          hsync,vsync;
    output [3:0]    vga_r, vga_g, vga_b;
    output reg[3:0] Enable_left, Enable_right;
    output reg[7:0] Seven_Seg_left, Seven_Seg_right;
    output reg[15:0] led;
    
    wire S0_out, S1_out, S2_out, S3_out, S4_out;
    reg rst;
    reg [27:0] counter,count_time,bomb1_count,led_count;
    wire            pclk;
    wire            valid;
    wire [9:0]      h_cnt, v_cnt;
    reg [11:0]      vga_data;
    wire [13:0]     rom_dout[24:0];//24_four,23_bomb4,22_bomb3,21_bomb2,20_house,19_bomb4,18_bomb3,17_bomb2,16_enemy4,15_enemy3,14_enemy2,13_drug,12_water,11_three,10_two,9_one,8_zero,7_box,6_tree, 5_bomb1, 4_house, 3_tree, 2_box , 1_safe, 0_character
    reg [13:0]      rom_addr;
    reg [13:0]      rom_addr_bomb1, rom_addr_house2, rom_addr_house, rom_addr_tree2,rom_addr_tree, rom_addr_box2, rom_addr_box, rom_addr_safe, rom_addr_character;
    reg [13:0]      rom_addr_four, rom_addr_three, rom_addr_two, rom_addr_one, rom_addr_zero;
    reg [13:0]      rom_addr_water, rom_addr_enemy2, rom_addr_enemy3, rom_addr_enemy4, rom_addr_bomb2, rom_addr_bomb3, rom_addr_bomb4, rom_addr_drug;
    wire [7:0] house_area;
    wire [6:0] tree_area;
    wire [4:0] tree_area_21,tree_area_22;
    wire [3:0] house_area_21,house_area_22;
    wire [5:0] box_area_21,box_area_22;
    wire [1:0] enemy2_area,enemy3_area,enemy4_area;
    wire drug_area,water_area;
    wire [1:0] tree_area2,safe_area,box_area,box_area2;
    wire character_area, bomb1_area;
    reg [9:0]       character_x, character_y, nextcharacter_x, nextcharacter_y;
    reg [9:0] bomb1_x, bomb1_y;
    reg [9:0] drug_x, drug_y;
    reg [3:0] position;
    reg drunk, buff;
    reg bomb1, bomb1_start;
    reg box1, box2, box3, box4, box5, box6, box7, box8, box9, box10, box11, box12, box13, box14, box15, box16;
    reg enemy1, enemy2, enemy3, enemy4, enemy5, enemy6;
    reg [3:0] ten_time, one_time, bomb1_time, led_time;
    reg [1:0] safe_number;
    reg [7:0] SevenSeg_ten, SevenSeg_one, SevenSeg_bomb, SevenSeg_safe,SevenSeg_bomb_time,SevenSeg_enemy;
    reg [1:0]Judge;
    reg [3:0]bomb_kind;
    reg [4:0]count_data;
    reg [7:0]bomb_data,bomb_data_temp;
    reg [3:0]enemy_number;
    reg level_1,level_2;
    reg [20:0]bonus_time_bomb_add[5:0],bonus_time_bomb_decrease[5:0],bonus_time_add[5:0],bonus_time_decrease[5:0];
    reg [6:0]level2_time;
    reg [20:0]add_total_bomb,decrease_total_bomb,add_total_time,decrease_total_time;
    
    parameter Success = 2'b11, Failed = 2'b10;
    parameter [9:0] logo_length=10'd30;
    parameter [9:0] logo_height=10'd50;
    
    always @(*)
    begin
        rst = ~ rst_pos;
    end
    
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            counter <= 0;
        else
            counter <= counter + 1;
    end
    
    always @(posedge ps2_clk or posedge rst)
    begin
    if(rst)
        begin
        bomb_data_temp <= 0;
        bomb_data <= 0;
        count_data <= 0;
        end
    else if(count_data == 0)
        begin
        if(Keyboard_Data == 0)
            count_data <= count_data + 1;
        else
            count_data <= count_data;
        end
    else if(count_data <= 5'd8)
        begin
            count_data <= count_data + 1;
            bomb_data_temp[count_data-1] <= Keyboard_Data;
        end
    else if(count_data == 5'd9 || count_data == 5'd10)
        begin
            if(bomb_data_temp == 8'hf0)
                count_data <= count_data + 1;
            else
            begin
                if(count_data == 5'd10)
                    begin
                    count_data <=0;
                    case(bomb_data_temp)
                    8'h2b:bomb_data <= 8'h2b; //bomb1F
                    8'h15:bomb_data <= 8'h15; //bomb2Q
                    8'h1d:bomb_data <= 8'h1d; //bomb3W
                    8'h24:bomb_data <= 8'h24; //bomb4E
                    default:bomb_data <= 0;
                    endcase
                    end
                else
                    count_data <= count_data + 1;
            end
        end
    else if(count_data >= 5'd11 && count_data <= 5'd20)
        count_data <= count_data + 1;
    else
        begin
        count_data <= 0;
        bomb_data <= 0;
        end
    if(rst)
        bomb_kind <= 4'b0001;
    else if(level == 0)
        bomb_kind <= 4'b0001;
    else if(level == 1 && bomb1_time == 0)
        begin
        case(bomb_data)
        8'h2b:bomb_kind <= 4'b0001;
        8'h15:bomb_kind <= 4'b0010;
        8'h1d:bomb_kind <= 4'b0100;
        8'h24:bomb_kind <= 4'b1000;
        default:bomb_kind <= bomb_kind;
        endcase
        end
    end
    
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            begin
            count_time <= 0;
            ten_time <= 4'd3;
            one_time <= 0;
            level_1 <= 0;
            level_2 <= 0;
            bonus_time_add[0] <= 0;
            bonus_time_add[1] <= 0;
            bonus_time_add[2] <= 0;
            bonus_time_add[3] <= 0;
            bonus_time_add[4] <= 0;
            bonus_time_add[5] <= 0;
            bonus_time_decrease[0] <= 0;
            bonus_time_decrease[1] <= 0;
            bonus_time_decrease[2] <= 0;
            bonus_time_decrease[3] <= 0;
            bonus_time_decrease[4] <= 0;
            bonus_time_decrease[5] <= 0;
            level2_time <= 7'd60;
            add_total_time <= 0;
            decrease_total_time <= 21'd6000;
            end
        else if((level == 0)&&(level_1 == 0))
            begin
            level_1 <= 1;
            ten_time <= 4'd3;
            end
        else if((level == 1)&&(level_2 == 0))
            begin
            level_2 <= 1;
            ten_time <= 4'd6;
            end
        else if(count_time == 28'd100000000&&Judge==0&&level == 0)
            begin
            count_time <= 0;
            if(one_time == 0)
            begin
                if(ten_time != 0)
                begin
                ten_time <= ten_time - 1;
                one_time <= 4'd9;
                end
                else
                begin
                ten_time <= 0;
                one_time <= 0;
                end
            end
            else
            begin
            ten_time <= ten_time;
            one_time <= one_time - 1;
            end
            end
        else if(count_time == 28'd100000000&&Judge==0&&level == 1)
            begin
            count_time <= 0;
                begin
                    level2_time <= (level2_time + add_total_bomb - add_total_time + decrease_total_bomb - decrease_total_time - 1);
                    add_total_time <= add_total_bomb;
                    decrease_total_time <= decrease_total_bomb;
                end
            end
        else
            begin
            count_time <= count_time + 1;
            if(level == 1)
            begin
            case(level2_time)
            7'd00:begin ten_time <= 0;one_time <= 0; end
            7'd01:begin ten_time <= 0;one_time <= 1; end
            7'd02:begin ten_time <= 0;one_time <= 2; end
            7'd03:begin ten_time <= 0;one_time <= 3; end
            7'd04:begin ten_time <= 0;one_time <= 4; end
            7'd05:begin ten_time <= 0;one_time <= 5; end
            7'd06:begin ten_time <= 0;one_time <= 6; end
            7'd07:begin ten_time <= 0;one_time <= 7; end
            7'd08:begin ten_time <= 0;one_time <= 8; end
            7'd09:begin ten_time <= 0;one_time <= 9; end
            7'd10:begin ten_time <= 1;one_time <= 0; end
            7'd11:begin ten_time <= 1;one_time <= 1; end
            7'd12:begin ten_time <= 1;one_time <= 2; end
            7'd13:begin ten_time <= 1;one_time <= 3; end
            7'd14:begin ten_time <= 1;one_time <= 4; end
            7'd15:begin ten_time <= 1;one_time <= 5; end
            7'd16:begin ten_time <= 1;one_time <= 6; end
            7'd17:begin ten_time <= 1;one_time <= 7; end
            7'd18:begin ten_time <= 1;one_time <= 8; end
            7'd19:begin ten_time <= 1;one_time <= 9; end
            7'd20:begin ten_time <= 2;one_time <= 0; end
            7'd21:begin ten_time <= 2;one_time <= 1; end
            7'd22:begin ten_time <= 2;one_time <= 2; end
            7'd23:begin ten_time <= 2;one_time <= 3; end
            7'd24:begin ten_time <= 2;one_time <= 4; end
            7'd25:begin ten_time <= 2;one_time <= 5; end
            7'd26:begin ten_time <= 2;one_time <= 6; end
            7'd27:begin ten_time <= 2;one_time <= 7; end
            7'd28:begin ten_time <= 2;one_time <= 8; end
            7'd29:begin ten_time <= 2;one_time <= 9; end
            7'd30:begin ten_time <= 3;one_time <= 0; end
            7'd31:begin ten_time <= 3;one_time <= 1; end
            7'd32:begin ten_time <= 3;one_time <= 2; end
            7'd33:begin ten_time <= 3;one_time <= 3; end
            7'd34:begin ten_time <= 3;one_time <= 4; end
            7'd35:begin ten_time <= 3;one_time <= 5; end
            7'd36:begin ten_time <= 3;one_time <= 6; end
            7'd37:begin ten_time <= 3;one_time <= 7; end
            7'd38:begin ten_time <= 3;one_time <= 8; end
            7'd39:begin ten_time <= 3;one_time <= 9; end
            7'd40:begin ten_time <= 4;one_time <= 0; end
            7'd41:begin ten_time <= 4;one_time <= 1; end
            7'd42:begin ten_time <= 4;one_time <= 2; end
            7'd43:begin ten_time <= 4;one_time <= 3; end
            7'd44:begin ten_time <= 4;one_time <= 4; end
            7'd45:begin ten_time <= 4;one_time <= 5; end
            7'd46:begin ten_time <= 4;one_time <= 6; end
            7'd47:begin ten_time <= 4;one_time <= 7; end
            7'd48:begin ten_time <= 4;one_time <= 8; end
            7'd49:begin ten_time <= 4;one_time <= 9; end
            7'd50:begin ten_time <= 5;one_time <= 0; end
            7'd51:begin ten_time <= 5;one_time <= 1; end
            7'd52:begin ten_time <= 5;one_time <= 2; end
            7'd53:begin ten_time <= 5;one_time <= 3; end
            7'd54:begin ten_time <= 5;one_time <= 4; end
            7'd55:begin ten_time <= 5;one_time <= 5; end
            7'd56:begin ten_time <= 5;one_time <= 6; end
            7'd57:begin ten_time <= 5;one_time <= 7; end
            7'd58:begin ten_time <= 5;one_time <= 8; end
            7'd59:begin ten_time <= 5;one_time <= 9; end
            7'd60:begin ten_time <= 6;one_time <= 0; end
            default:begin ten_time <= 0;one_time <= 0; end
            endcase
            end
            end
    end
    
    always @(*)
    begin
    add_total_bomb = bonus_time_bomb_add[0] + bonus_time_bomb_add[1] + bonus_time_bomb_add[2] + bonus_time_bomb_add[3] + bonus_time_bomb_add[4] + bonus_time_bomb_add[5];
    decrease_total_bomb = bonus_time_bomb_decrease[0] + bonus_time_bomb_decrease[1] + bonus_time_bomb_decrease[2] + bonus_time_bomb_decrease[3] + bonus_time_bomb_decrease[4] + bonus_time_bomb_decrease[5];
    end
    
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            begin
            bomb1_count <= 0;
            bomb1_time <= 0;
            end
        else if(bomb1_start)
        begin
            if(level == 0)
            begin
            bomb1_time <= 3;
            bomb1_count <= 0;
            end
            else if(level == 1)
            begin
            case(bomb_kind)
            4'b0001:bomb1_time <= 1;
            4'b0010:bomb1_time <= 2;
            4'b0100:bomb1_time <= 3;
            4'b1000:bomb1_time <= 4;
            default:bomb1_time <= 0;
            endcase
            bomb1_count <= 0;
            end
        end
        else if(bomb1_count == 28'd100000000&&bomb1_time!=0)
            begin
                bomb1_count <= 0;
                bomb1_time <= bomb1_time - 1;
            end
        else
        begin
            bomb1_count <= bomb1_count + 1;
            bomb1_time <= bomb1_time;
        end
    end
    
    always @(*)
    begin
    enemy_number = enemy1+enemy2+enemy3+enemy4+enemy5+enemy6;
    end
    
    always @(posedge counter[17] or posedge rst)
    begin
    if(rst)
        begin
        Enable_left <= 0;
        Enable_right <= 0;
        SevenSeg_ten <= 0;
        SevenSeg_one <= 0;
        SevenSeg_safe <= 0;
        Seven_Seg_left <= 0;
        Seven_Seg_right <= 0;
        
        end
    else
        begin
        case(ten_time)
        4'b0000: SevenSeg_ten<=8'b0011_1111;  
        4'b0001: SevenSeg_ten<=8'b0000_0110;  
        4'b0010: SevenSeg_ten<=8'b0101_1011;  
        4'b0011: SevenSeg_ten<=8'b0100_1111;  
        4'b0100: SevenSeg_ten<=8'b0110_0110;  
        4'b0101: SevenSeg_ten<=8'b0110_1101;  
        4'b0110: SevenSeg_ten<=8'b0111_1101;
        default: SevenSeg_ten<=8'b0000_0000;
        endcase
        case(one_time)
        4'b0000: SevenSeg_one<=8'b0011_1111;  
        4'b0001: SevenSeg_one<=8'b0000_0110;  
        4'b0010: SevenSeg_one<=8'b0101_1011;  
        4'b0011: SevenSeg_one<=8'b0100_1111;  
        4'b0100: SevenSeg_one<=8'b0110_0110;  
        4'b0101: SevenSeg_one<=8'b0110_1101;  
        4'b0110: SevenSeg_one<=8'b0111_1101;  
        4'b0111: SevenSeg_one<=8'b0000_0111;  
        4'b1000: SevenSeg_one<=8'b0111_1111;  
        4'b1001: SevenSeg_one<=8'b0110_1111;
        default: SevenSeg_one<=8'b0000_0000;
        endcase
        case(bomb_kind)  
        4'b0001: SevenSeg_bomb<=8'b0000_0110;  
        4'b0010: SevenSeg_bomb<=8'b0101_1011;  
        4'b0100: SevenSeg_bomb<=8'b0100_1111;
        4'b1000: SevenSeg_bomb<=8'b0110_0110;  
        default: SevenSeg_bomb<=8'b0000_0000;
        endcase
        case(bomb1_time)  
        4'b0001: SevenSeg_bomb_time<=8'b0000_0110;  
        4'b0010: SevenSeg_bomb_time<=8'b0101_1011;  
        4'b0100: SevenSeg_bomb_time<=8'b0100_1111;
        4'b1000: SevenSeg_bomb_time<=8'b0110_0110;  
        default: SevenSeg_bomb_time<=8'b0000_0000;
        endcase
        case(safe_number)
        2'b00: SevenSeg_safe<=8'b0011_1111;  
        2'b01: SevenSeg_safe<=8'b0000_0110;  
        2'b10: SevenSeg_safe<=8'b0000_0110;
        2'b11: SevenSeg_safe<=8'b0101_1011;
        default:SevenSeg_safe<=8'b0000_0000;
        endcase
        case(enemy_number)
        4'b0000: SevenSeg_enemy<=8'b0011_1111;  
        4'b0001: SevenSeg_enemy<=8'b0000_0110;  
        4'b0010: SevenSeg_enemy<=8'b0101_1011;  
        4'b0011: SevenSeg_enemy<=8'b0100_1111;  
        4'b0100: SevenSeg_enemy<=8'b0110_0110;  
        4'b0101: SevenSeg_enemy<=8'b0110_1101;  
        4'b0110: SevenSeg_enemy<=8'b0111_1101;
        default: SevenSeg_enemy<=8'b0000_0000;
        endcase
        case(Enable_left)
        4'b0000:begin Enable_left <= 4'b0001; Seven_Seg_left <= SevenSeg_one; end
        4'b0001:begin Enable_left <= 4'b0010; Seven_Seg_left <= SevenSeg_ten; end
        4'b0010:begin Enable_left <= 4'b0100; Seven_Seg_left <= 0;end
        4'b0100:begin Enable_left <= 4'b1000; 
                    if(level == 0)
                    Seven_Seg_left <= 8'b0000_0110; 
                    else
                    Seven_Seg_left <= 8'b0101_1011;
                    end
        default:begin Enable_left <= 4'b0001; Seven_Seg_left <= SevenSeg_one; end
        endcase
        case(Enable_right)
        4'b0000:begin Enable_right <= 4'b0001; Seven_Seg_right <= SevenSeg_bomb_time; end
        4'b0001:begin Enable_right <= 4'b0010; Seven_Seg_right <= 0; end
        4'b0010:begin Enable_right <= 4'b0100; 
                   if(level == 0)
                       Seven_Seg_right <= SevenSeg_safe;
                   else if(level == 1)
                       Seven_Seg_right <= SevenSeg_enemy;
                   else
                       Seven_Seg_right <= 0;
               end
        4'b0100:begin Enable_right <= 4'b1000; Seven_Seg_right <= 0; end
        default:begin Enable_right <= 4'b0001; Seven_Seg_right <= SevenSeg_bomb; end
        endcase
        end
    end
    
    dcm_25M u0(
          .clk_in1(clk),      
          .clk_out1(pclk),
          .reset(rst));
    
    Debounce D0(counter[16], S0, S0_out);
    Debounce D1(counter[16], S1, S1_out);
    Debounce D2(counter[16], S2, S2_out);
    Debounce D3(counter[16], S3, S3_out);
    Debounce D4(counter[16], S4, S4_out);
    //5_bomb1, 4_house, 3_tree, 2_box , 1_safe, 0_character
    logo_rom_character a0(
                .clka(pclk),
                .addra(rom_addr_character),
                .douta(rom_dout[0]));
    logo_rom_safe a1(
                .clka(pclk),
                .addra(rom_addr_safe),
                .douta(rom_dout[1]));
    logo_rom_box a2(
                .clka(pclk),
                .addra(rom_addr_box),
                .douta(rom_dout[2]));
    logo_rom_box a22(
                .clka(pclk),
                .addra(rom_addr_box2),
                .douta(rom_dout[7]));
    logo_rom_tree a3(
                .clka(pclk),
                .addra(rom_addr_tree),
                .douta(rom_dout[3]));
    logo_rom_tree a32(
                .clka(pclk),
                .addra(rom_addr_tree2),
                .douta(rom_dout[6]));
    logo_rom_house a4(
                .clka(pclk),
                .addra(rom_addr_house),
                .douta(rom_dout[4]));
    logo_rom_house a42(
                .clka(pclk),
                .addra(rom_addr_house2),
                .douta(rom_dout[20]));
    logo_rom_bomb1 a51(
                .clka(pclk),
                .addra(rom_addr_bomb1),
                .douta(rom_dout[5]));
    logo_rom_bomb2 a52(
                .clka(pclk),
                .addra(rom_addr_bomb1),
                .douta(rom_dout[21]));
    logo_rom_bomb3 a53(
                .clka(pclk),
                .addra(rom_addr_bomb1),
                .douta(rom_dout[22]));
    logo_rom_bomb4 a54(
                .clka(pclk),
                .addra(rom_addr_bomb1),
                .douta(rom_dout[23]));
    logo_rom_zero a8(
                .clka(pclk),
                .addra(rom_addr_zero),
                .douta(rom_dout[8]));
    logo_rom_one a9(
                .clka(pclk),
                .addra(rom_addr_one),
                .douta(rom_dout[9]));
    logo_rom_two a10(
                .clka(pclk),
                .addra(rom_addr_two),
                .douta(rom_dout[10]));
    logo_rom_three a11(
                .clka(pclk),
                .addra(rom_addr_three),
                .douta(rom_dout[11]));
    logo_rom_four a44(
                .clka(pclk),
                .addra(rom_addr_four),
                .douta(rom_dout[24]));
    logo_rom_enemy2 a12(
                .clka(pclk),
                .addra(rom_addr_enemy2),
                .douta(rom_dout[14]));
    logo_rom_enemy3 a13(
                .clka(pclk),
                .addra(rom_addr_enemy3),
                .douta(rom_dout[15]));
    logo_rom_enemy4 a14(
                .clka(pclk),
                .addra(rom_addr_enemy4),
                .douta(rom_dout[16]));
    logo_rom_water a15(
                .clka(pclk),
                .addra(rom_addr_water),
                .douta(rom_dout[12]));
    logo_rom_drug a16(
                .clka(pclk),
                .addra(rom_addr_drug),
                .douta(rom_dout[13]));
    SyncGeneration u1 (
        .pclk(pclk),
        .reset(rst),
        .hSync(hsync),
        .vSync(vsync),
        .dataValid(valid),
        .hDataCnt(h_cnt),
        .vDataCnt(v_cnt) );
    
    assign house_area[0] = ((v_cnt >= 10'd6)&(v_cnt <= 10'd55)&(h_cnt >= 10'd86)&(h_cnt <= 10'd115))?1'b1 : 1'b0;
    assign house_area[1] = ((v_cnt >= 10'd66)&(v_cnt <= 10'd115)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;
    assign house_area[2] = ((v_cnt >= 10'd126)&(v_cnt <= 10'd175)&(h_cnt >= 10'd6)&(h_cnt <= 10'd35))?1'b1 : 1'b0;
    assign house_area[3] = ((v_cnt >= 10'd186)&(v_cnt <= 10'd235)&(h_cnt >= 10'd86)&(h_cnt <= 10'd115))?1'b1 : 1'b0;
    assign house_area[4] = ((v_cnt >= 10'd246)&(v_cnt <= 10'd295)&(h_cnt >= 10'd86)&(h_cnt <= 10'd115))?1'b1 : 1'b0;
    assign house_area[5] = ((v_cnt >= 10'd306)&(v_cnt <= 10'd355)&(h_cnt >= 10'd6)&(h_cnt <= 10'd35))?1'b1 : 1'b0;
    assign house_area[6] = ((v_cnt >= 10'd366)&(v_cnt <= 10'd415)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;
    assign house_area[7] = ((v_cnt >= 10'd426)&(v_cnt <= 10'd475)&(h_cnt >= 10'd86)&(h_cnt <= 10'd115))?1'b1 : 1'b0;
    assign tree_area[0] = ((v_cnt >= 10'd66)&(v_cnt <= 10'd115)&(h_cnt >= 10'd206)&(h_cnt <= 10'd235))?1'b1 : 1'b0;
    assign tree_area[1] = ((v_cnt >= 10'd126)&(v_cnt <= 10'd175)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign tree_area[2] = ((v_cnt >= 10'd186)&(v_cnt <= 10'd235)&(h_cnt >= 10'd206)&(h_cnt <= 10'd235))?1'b1 : 1'b0;
    assign tree_area[3] = ((v_cnt >= 10'd246)&(v_cnt <= 10'd295)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign tree_area[4] = ((v_cnt >= 10'd306)&(v_cnt <= 10'd355)&(h_cnt >= 10'd286)&(h_cnt <= 10'd315))?1'b1 : 1'b0;
    assign tree_area[5] = ((v_cnt >= 10'd366)&(v_cnt <= 10'd415)&(h_cnt >= 10'd206)&(h_cnt <= 10'd235))?1'b1 : 1'b0;
    assign tree_area[6] = ((v_cnt >= 10'd426)&(v_cnt <= 10'd475)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign tree_area2[0] = ((v_cnt >= 10'd66)&(v_cnt <= 10'd115)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign tree_area2[1] = ((v_cnt >= 10'd306)&(v_cnt <= 10'd355)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;    
    assign safe_area[0] = ((v_cnt >= 10'd6)&(v_cnt <= 10'd55)&(h_cnt >= 10'd6)&(h_cnt <= 10'd35)&safe_number[1])?1'b1 : 1'b0;
    assign safe_area[1] = ((v_cnt >= 10'd186)&(v_cnt <= 10'd235)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275)&safe_number[0])?1'b1 : 1'b0;
    assign box_area[0] = ((v_cnt >= 10'd66)&(v_cnt <= 10'd115)&(h_cnt >= 10'd46)&(h_cnt <= 10'd75)&box1)?1'b1 : 1'b0;//B1
    assign box_area[1] = ((v_cnt >= 10'd306)&(v_cnt <= 10'd355)&(h_cnt >= 10'd46)&(h_cnt <= 10'd75)&box2)?1'b1 : 1'b0;//F1
    assign box_area2[0] = ((v_cnt >= 10'd66)&(v_cnt <= 10'd115)&(h_cnt >= 10'd126)&(h_cnt <= 10'd155)&box3)?1'b1 : 1'b0;//B3
    assign box_area2[1] = ((v_cnt >= 10'd306)&(v_cnt <= 10'd355)&(h_cnt >= 10'd126)&(h_cnt <= 10'd155)&box4)?1'b1 : 1'b0;//F3
    assign character_area=((v_cnt>=character_y)&(v_cnt<=character_y+logo_height-1)&(h_cnt>=character_x)&(h_cnt<=character_x+logo_length-1))?1'b1:1'b0;
    assign bomb1_area=((v_cnt>=bomb1_y)&(v_cnt<=bomb1_y+logo_height-1)&(h_cnt>=bomb1_x)&(h_cnt<=bomb1_x+logo_length-1))?1'b1:1'b0;
    
    assign enemy2_area[0]=((v_cnt >= 10'd6)&(v_cnt <= 10'd55)&(h_cnt >= 10'd6)&(h_cnt <= 10'd35)&enemy1)?1'b1 : 1'b0;
    assign enemy2_area[1]=((v_cnt >= 10'd126)&(v_cnt <= 10'd175)&(h_cnt >= 10'd6)&(h_cnt <= 10'd35)&enemy2)?1'b1 : 1'b0;
    assign enemy4_area[0]=((v_cnt >= 10'd6)&(v_cnt <= 10'd55)&(h_cnt >= 10'd206)&(h_cnt <= 10'd235)&enemy3)?1'b1 : 1'b0;
    assign enemy4_area[1]=((v_cnt >= 10'd126)&(v_cnt <= 10'd175)&(h_cnt >= 10'd206)&(h_cnt <= 10'd235)&enemy4)?1'b1 : 1'b0;
    assign enemy3_area[0]=((v_cnt >= 10'd6)&(v_cnt <= 10'd55)&(h_cnt >= 10'd286)&(h_cnt <= 10'd315)&enemy5)?1'b1 : 1'b0;
    assign enemy3_area[1]=((v_cnt >= 10'd126)&(v_cnt <= 10'd175)&(h_cnt >= 10'd286)&(h_cnt <= 10'd315)&enemy6)?1'b1 : 1'b0;
    assign drug_area=((v_cnt>=drug_y)&(v_cnt<=drug_y+logo_height-1)&(h_cnt>=drug_x)&(h_cnt<=drug_x+logo_length-1))?1'b1:1'b0;
    assign water_area=((v_cnt >= 10'd426)&(v_cnt <= 10'd475)&(h_cnt >= 10'd286)&(h_cnt <= 10'd315))?1'b1 : 1'b0;
    assign house_area_21[0] = ((v_cnt >= 10'd66)&(v_cnt <= 10'd115)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;
    assign house_area_21[1] = ((v_cnt >= 10'd186)&(v_cnt <= 10'd235)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;
    assign house_area_21[2] = ((v_cnt >= 10'd246)&(v_cnt <= 10'd295)&(h_cnt >= 10'd6)&(h_cnt <= 10'd35))?1'b1 : 1'b0;
    assign house_area_21[3] = ((v_cnt >= 10'd366)&(v_cnt <= 10'd415)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;
    assign house_area_22[0] = ((v_cnt >= 10'd66)&(v_cnt <= 10'd115)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign house_area_22[1] = ((v_cnt >= 10'd186)&(v_cnt <= 10'd235)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign house_area_22[2] = ((v_cnt >= 10'd246)&(v_cnt <= 10'd295)&(h_cnt >= 10'd86)&(h_cnt <= 10'd115))?1'b1 : 1'b0;
    assign house_area_22[3] = ((v_cnt >= 10'd366)&(v_cnt <= 10'd415)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign tree_area_21[0] = ((v_cnt >= 10'd6)&(v_cnt <= 10'd55)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;
    assign tree_area_21[1] = ((v_cnt >= 10'd126)&(v_cnt <= 10'd175)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;
    assign tree_area_21[2] = ((v_cnt >= 10'd246)&(v_cnt <= 10'd295)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;
    assign tree_area_21[3] = ((v_cnt >= 10'd366)&(v_cnt <= 10'd415)&(h_cnt >= 10'd6)&(h_cnt <= 10'd35))?1'b1 : 1'b0;
    assign tree_area_21[4] = ((v_cnt >= 10'd426)&(v_cnt <= 10'd475)&(h_cnt >= 10'd166)&(h_cnt <= 10'd195))?1'b1 : 1'b0;
    assign tree_area_22[0] = ((v_cnt >= 10'd6)&(v_cnt <= 10'd55)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign tree_area_22[1] = ((v_cnt >= 10'd126)&(v_cnt <= 10'd175)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign tree_area_22[2] = ((v_cnt >= 10'd246)&(v_cnt <= 10'd295)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign tree_area_22[3] = ((v_cnt >= 10'd366)&(v_cnt <= 10'd415)&(h_cnt >= 10'd86)&(h_cnt <= 10'd115))?1'b1 : 1'b0;
    assign tree_area_22[4] = ((v_cnt >= 10'd426)&(v_cnt <= 10'd475)&(h_cnt >= 10'd246)&(h_cnt <= 10'd275))?1'b1 : 1'b0;
    assign box_area_21[0] = ((v_cnt >= 10'd6)&(v_cnt <= 10'd55)&(h_cnt >= 10'd46)&(h_cnt <= 10'd75)&box5)?1'b1 : 1'b0;
    assign box_area_21[1] = ((v_cnt >= 10'd66)&(v_cnt <= 10'd115)&(h_cnt >= 10'd46)&(h_cnt <= 10'd75)&box6)?1'b1 : 1'b0;
    assign box_area_21[2] = ((v_cnt >= 10'd126)&(v_cnt <= 10'd175)&(h_cnt >= 10'd46)&(h_cnt <= 10'd75)&box7)?1'b1 : 1'b0;
    assign box_area_21[3] = ((v_cnt >= 10'd186)&(v_cnt <= 10'd235)&(h_cnt >= 10'd46)&(h_cnt <= 10'd75)&box8)?1'b1 : 1'b0;
    assign box_area_21[4] = ((v_cnt >= 10'd246)&(v_cnt <= 10'd295)&(h_cnt >= 10'd46)&(h_cnt <= 10'd75)&box9)?1'b1 : 1'b0;
    assign box_area_21[5] = ((v_cnt >= 10'd366)&(v_cnt <= 10'd415)&(h_cnt >= 10'd46)&(h_cnt <= 10'd75)&box10)?1'b1 : 1'b0;
    assign box_area_22[0] = ((v_cnt >= 10'd6)&(v_cnt <= 10'd55)&(h_cnt >= 10'd126)&(h_cnt <= 10'd155)&box11)?1'b1 : 1'b0;
    assign box_area_22[1] = ((v_cnt >= 10'd66)&(v_cnt <= 10'd115)&(h_cnt >= 10'd126)&(h_cnt <= 10'd155)&box12)?1'b1 : 1'b0;
    assign box_area_22[2] = ((v_cnt >= 10'd126)&(v_cnt <= 10'd175)&(h_cnt >= 10'd126)&(h_cnt <= 10'd155)&box13)?1'b1 : 1'b0;
    assign box_area_22[3] = ((v_cnt >= 10'd186)&(v_cnt <= 10'd235)&(h_cnt >= 10'd126)&(h_cnt <= 10'd155)&box14)?1'b1 : 1'b0;
    assign box_area_22[4] = ((v_cnt >= 10'd246)&(v_cnt <= 10'd295)&(h_cnt >= 10'd126)&(h_cnt <= 10'd155)&box15)?1'b1 : 1'b0;
    assign box_area_22[5] = ((v_cnt >= 10'd366)&(v_cnt <= 10'd415)&(h_cnt >= 10'd126)&(h_cnt <= 10'd155)&box16)?1'b1 : 1'b0;
    
    always @(posedge pclk or posedge rst)
    begin
    if(rst)
        begin
        rom_addr_bomb1 <= 0;
        rom_addr_house <= 0;
        rom_addr_house2 <= 0;
        rom_addr_tree <= 0;
        rom_addr_tree2 <= 0;
        rom_addr_box <= 0;
        rom_addr_box2 <= 0;
        rom_addr_safe <= 0;
        rom_addr_character <= 0;
        rom_addr_zero <= 0;
        rom_addr_one <= 0;
        rom_addr_two <= 0;
        rom_addr_three <= 0;
        rom_addr_four <= 0;
        rom_addr_enemy2 <= 0;
        rom_addr_enemy3 <= 0;
        rom_addr_enemy4 <= 0;
        rom_addr_water <= 0;
        rom_addr_drug <= 0;
        vga_data <= 0;
        end
    else if(level == 0)
        begin
            if(valid)
                begin
                if(((v_cnt <= 10'd5) || (v_cnt >= 10'd476))&(h_cnt <= 10'd320) || (h_cnt <= 10'd5) || ((h_cnt >= 10'd316)&&(h_cnt <= 10'd320)))
                begin
                vga_data <= 12'h777;
                end
                else if(house_area != 0)
                begin
                if(rom_addr_house == 14'd1499)
                    rom_addr_house <= 0;
                else
                    rom_addr_house <= rom_addr_house + 1;
                vga_data <= rom_dout[4];
                end
                else if(tree_area != 0)
                begin
                if(rom_addr_tree == 14'd1499)
                    rom_addr_tree <= 0;
                else
                    rom_addr_tree <= rom_addr_tree + 1;
                vga_data <= rom_dout[3];
                end
                else if(tree_area2 != 0)
                begin
                if(rom_addr_tree2 == 14'd1499)
                    rom_addr_tree2 <= 0;
                else
                    rom_addr_tree2 <= rom_addr_tree2 + 1;
                vga_data <= rom_dout[6];
                end
                else if(safe_area != 0)
                begin
                if(rom_addr_safe == 14'd1499)
                    rom_addr_safe <= 0;
                else
                    rom_addr_safe <= rom_addr_safe + 1;
                vga_data <= rom_dout[1];
                end
                else if(box_area != 0)
                begin
                if(rom_addr_box == 14'd1499)
                    rom_addr_box <= 0;
                else
                    rom_addr_box <= rom_addr_box + 1;
                vga_data <= rom_dout[2];
                end
                else if(box_area2 != 0)
                begin
                if(rom_addr_box2 == 14'd1499)
                    rom_addr_box2 <= 0;
                else
                    rom_addr_box2 <= rom_addr_box2 + 1;
                vga_data <= rom_dout[7];
                end
                else if(character_area != 0)
                begin
                if(rom_addr_character == 14'd1499)
                    rom_addr_character <= 0;
                else
                    rom_addr_character <= rom_addr_character + 1;
                    vga_data <= rom_dout[0];
                end
                else if(bomb1_area != 0&&bomb1_time!=0)
                begin
                if(rom_addr_bomb1 == 14'd1499)
                    rom_addr_bomb1 <= 0;
                else
                    rom_addr_bomb1 <= rom_addr_bomb1 + 1;
                    vga_data <= rom_dout[5];
                end
                else if((v_cnt >= 10'd191)&(v_cnt <= 10'd290)&(h_cnt >= 10'd351)&(h_cnt <= 10'd410)&(bomb1_time == 4'd0))
                begin
                if(rom_addr_zero == 14'd5999)
                    rom_addr_zero <= 0;
                else
                    rom_addr_zero <= rom_addr_zero + 1;
                    vga_data <= rom_dout[8];
                end
                else if((v_cnt >= 10'd191)&(v_cnt <= 10'd290)&(h_cnt >= 10'd351)&(h_cnt <= 10'd410)&(bomb1_time == 4'd1))
                begin
                if(rom_addr_one == 14'd5999)
                    rom_addr_one <= 0;
                else
                    rom_addr_one <= rom_addr_one + 1;
                    vga_data <= rom_dout[9];
                end
                else if((v_cnt >= 10'd191)&(v_cnt <= 10'd290)&(h_cnt >= 10'd351)&(h_cnt <= 10'd410)&(bomb1_time == 4'd2))
                begin
                if(rom_addr_two == 14'd5999)
                    rom_addr_two <= 0;
                else
                    rom_addr_two <= rom_addr_two + 1;
                    vga_data <= rom_dout[10];
                end
                else if((v_cnt >= 10'd191)&(v_cnt <= 10'd290)&(h_cnt >= 10'd351)&(h_cnt <= 10'd410)&(bomb1_time == 4'd3))
                begin
                if(rom_addr_three == 14'd5999)
                    rom_addr_three <= 0;
                else
                    rom_addr_three <= rom_addr_three + 1;
                    vga_data <= rom_dout[11];
                end
                else if(h_cnt >= 10'd321)
                begin
                vga_data <= 12'h000;
                end
                else
                begin
                rom_addr_bomb1 <= rom_addr_bomb1;
                rom_addr_house <= rom_addr_house;
                rom_addr_tree <= rom_addr_tree;
                rom_addr_tree2 <= rom_addr_tree2;
                rom_addr_box <= rom_addr_box;
                rom_addr_box2 <= rom_addr_box2;
                rom_addr_safe <= rom_addr_safe;
                rom_addr_character <= rom_addr_character;
                rom_addr_bomb1 <= rom_addr_bomb1;
                rom_addr_zero <= rom_addr_zero;
                rom_addr_one <= rom_addr_one;
                rom_addr_two <= rom_addr_two;
                rom_addr_three <= rom_addr_three;
                vga_data <= 12'hfff;
                end
                end
            else
                begin
                vga_data <= 12'h000;
                    if(v_cnt == 0)
                        begin
                        rom_addr_bomb1 <= 0;
                        rom_addr_house <= 0;
                        rom_addr_tree <= 0;
                        rom_addr_tree2 <= 0;
                        rom_addr_box <= 0;
                        rom_addr_box2 <= 0;
                        rom_addr_safe <= 0;
                        rom_addr_character <= 0;
                        rom_addr_zero <= 0;
                        rom_addr_one <= 0;
                        rom_addr_two <= 0;
                        rom_addr_three <= 0;
                        end
                    else
                        begin
                        rom_addr_bomb1 <= rom_addr_bomb1;
                        rom_addr_house <= rom_addr_house;
                        rom_addr_tree <= rom_addr_tree;
                        rom_addr_tree2 <= rom_addr_tree2;
                        rom_addr_box <= rom_addr_box;
                        rom_addr_box2 <= rom_addr_box2;
                        rom_addr_safe <= rom_addr_safe;
                        rom_addr_character <= rom_addr_character;
                        rom_addr_zero <= rom_addr_zero;
                        rom_addr_one <= rom_addr_one;
                        rom_addr_two <= rom_addr_two;
                        rom_addr_three <= rom_addr_three;
                        end
                end  
        end
    else if(level == 1)
        begin
            if(valid)
                begin
                if(((v_cnt <= 10'd5) || (v_cnt >= 10'd476))&(h_cnt <= 10'd320) || (h_cnt <= 10'd5) || ((h_cnt >= 10'd316)&&(h_cnt <= 10'd320)))
                begin
                vga_data <= 12'h777;
                end
                else if(house_area_21 != 0)
                begin
                if(rom_addr_house == 14'd1499)
                    rom_addr_house <= 0;
                else
                    rom_addr_house <= rom_addr_house + 1;
                vga_data <= rom_dout[4];
                end
                else if(house_area_22 != 0)
                begin
                if(rom_addr_house2 == 14'd1499)
                    rom_addr_house2 <= 0;
                else
                    rom_addr_house2 <= rom_addr_house2 + 1;
                vga_data <= rom_dout[20];
                end
                else if(tree_area_21 != 0)
                begin
                if(rom_addr_tree == 14'd1499)
                    rom_addr_tree <= 0;
                else
                    rom_addr_tree <= rom_addr_tree + 1;
                vga_data <= rom_dout[3];
                end
                else if(tree_area_22 != 0)
                begin
                if(rom_addr_tree2 == 14'd1499)
                    rom_addr_tree2 <= 0;
                else
                    rom_addr_tree2 <= rom_addr_tree2 + 1;
                vga_data <= rom_dout[6];
                end
                else if(box_area_21 != 0)
                begin
                if(rom_addr_box == 14'd1499)
                    rom_addr_box <= 0;
                else
                    rom_addr_box <= rom_addr_box + 1;
                vga_data <= rom_dout[2];
                end
                else if(box_area_22 != 0)
                begin
                if(rom_addr_box2 == 14'd1499)
                    rom_addr_box2 <= 0;
                else
                    rom_addr_box2 <= rom_addr_box2 + 1;
                vga_data <= rom_dout[7];
                end
                else if(character_area != 0)
                begin
                if(rom_addr_character == 14'd1499)
                    rom_addr_character <= 0;
                else
                    rom_addr_character <= rom_addr_character + 1;
                    vga_data <= rom_dout[0];
                end
                else if(bomb1_area != 0&&bomb1_time!=0)
                begin
                if(rom_addr_bomb1 == 14'd1499)
                    rom_addr_bomb1 <= 0;
                else
                    rom_addr_bomb1 <= rom_addr_bomb1 + 1;
                    case(bomb_kind)
                    4'b0001:vga_data <= rom_dout[5];
                    4'b0010:vga_data <= rom_dout[21];
                    4'b0100:vga_data <= rom_dout[22];
                    4'b1000:vga_data <= rom_dout[23];
                    endcase
                end
                else if((v_cnt >= 10'd191)&(v_cnt <= 10'd290)&(h_cnt >= 10'd351)&(h_cnt <= 10'd410)&(bomb1_time == 4'd0))
                begin
                if(rom_addr_zero == 14'd5999)
                    rom_addr_zero <= 0;
                else
                    rom_addr_zero <= rom_addr_zero + 1;
                    vga_data <= rom_dout[8];
                end
                else if((v_cnt >= 10'd191)&(v_cnt <= 10'd290)&(h_cnt >= 10'd351)&(h_cnt <= 10'd410)&(bomb1_time == 4'd1))
                begin
                if(rom_addr_one == 14'd5999)
                    rom_addr_one <= 0;
                else
                    rom_addr_one <= rom_addr_one + 1;
                    vga_data <= rom_dout[9];
                end
                else if((v_cnt >= 10'd191)&(v_cnt <= 10'd290)&(h_cnt >= 10'd351)&(h_cnt <= 10'd410)&(bomb1_time == 4'd2))
                begin
                if(rom_addr_two == 14'd5999)
                    rom_addr_two <= 0;
                else
                    rom_addr_two <= rom_addr_two + 1;
                    vga_data <= rom_dout[10];
                end
                else if((v_cnt >= 10'd191)&(v_cnt <= 10'd290)&(h_cnt >= 10'd351)&(h_cnt <= 10'd410)&(bomb1_time == 4'd3))
                begin
                if(rom_addr_three == 14'd5999)
                    rom_addr_three <= 0;
                else
                    rom_addr_three <= rom_addr_three + 1;
                    vga_data <= rom_dout[11];
                end
                else if((v_cnt >= 10'd191)&(v_cnt <= 10'd290)&(h_cnt >= 10'd351)&(h_cnt <= 10'd410)&(bomb1_time == 4'd4))
                begin
                if(rom_addr_four == 14'd5999)
                    rom_addr_four <= 0;
                else
                    rom_addr_four <= rom_addr_four + 1;
                    vga_data <= rom_dout[24];
                end
                else if(enemy2_area !=0)
                begin
                if(rom_addr_enemy2 == 14'd1499)
                    rom_addr_enemy2 <= 0;
                else
                    rom_addr_enemy2 <= rom_addr_enemy2 + 1;
                    vga_data <= rom_dout[14];
                end
                else if(enemy3_area !=0)
                begin
                if(rom_addr_enemy3 == 14'd1499)
                    rom_addr_enemy3 <= 0;
                else
                    rom_addr_enemy3 <= rom_addr_enemy3 + 1;
                    vga_data <= rom_dout[15];
                end
                else if(enemy4_area !=0)
                begin
                if(rom_addr_enemy4 == 14'd1499)
                    rom_addr_enemy4 <= 0;
                else
                    rom_addr_enemy4 <= rom_addr_enemy4 + 1;
                    vga_data <= rom_dout[16];
                end
                else if(drug_area !=0)
                begin
                if(rom_addr_drug == 14'd1499)
                    rom_addr_drug <= 0;
                else
                    rom_addr_drug <= rom_addr_drug + 1;
                    vga_data <= rom_dout[13];
                end
                else if(water_area !=0&&drunk==0)
                begin
                if(rom_addr_water == 14'd1499)
                    rom_addr_water <= 0;
                else
                    rom_addr_water <= rom_addr_water + 1;
                    vga_data <= rom_dout[12];
                end
                else if(h_cnt >= 10'd321)
                begin
                vga_data <= 12'h000;
                end
                else
                begin
                rom_addr_bomb1 <= rom_addr_bomb1;
                rom_addr_house <= rom_addr_house;
                rom_addr_house2 <= rom_addr_house2;
                rom_addr_tree <= rom_addr_tree;
                rom_addr_tree2 <= rom_addr_tree2;
                rom_addr_box <= rom_addr_box;
                rom_addr_box2 <= rom_addr_box2;
                rom_addr_safe <= rom_addr_safe;
                rom_addr_character <= rom_addr_character;
                rom_addr_bomb1 <= rom_addr_bomb1;
                rom_addr_zero <= rom_addr_zero;
                rom_addr_one <= rom_addr_one;
                rom_addr_two <= rom_addr_two;
                rom_addr_three <= rom_addr_three;
                rom_addr_four <= rom_addr_four;
                rom_addr_enemy2 <= rom_addr_enemy2;
                rom_addr_enemy3 <= rom_addr_enemy3;
                rom_addr_enemy4 <= rom_addr_enemy4;
                rom_addr_water <= rom_addr_water;
                rom_addr_drug <= rom_addr_drug;
                vga_data <= 12'hfff;
                end
                end
            else
                begin
                vga_data <= 12'h000;
                    if(v_cnt == 0)
                        begin
                        rom_addr_bomb1 <= 0;
                        rom_addr_house <= 0;
                        rom_addr_house2 <= 0;
                        rom_addr_tree <= 0;
                        rom_addr_tree2 <= 0;
                        rom_addr_box <= 0;
                        rom_addr_box2 <= 0;
                        rom_addr_safe <= 0;
                        rom_addr_character <= 0;
                        rom_addr_zero <= 0;
                        rom_addr_one <= 0;
                        rom_addr_two <= 0;
                        rom_addr_three <= 0;
                        rom_addr_four <= 0;
                        rom_addr_enemy2 <= 0;
                        rom_addr_enemy3 <= 0;
                        rom_addr_enemy4 <= 0;
                        rom_addr_water <= 0;
                        rom_addr_drug <= 0;
                        end
                    else
                        begin
                        rom_addr_bomb1 <= rom_addr_bomb1;
                        rom_addr_house <= rom_addr_house;
                        rom_addr_house2 <= rom_addr_house2;
                        rom_addr_tree <= rom_addr_tree;
                        rom_addr_tree2 <= rom_addr_tree2;
                        rom_addr_box <= rom_addr_box;
                        rom_addr_box2 <= rom_addr_box2;
                        rom_addr_safe <= rom_addr_safe;
                        rom_addr_character <= rom_addr_character;
                        rom_addr_zero <= rom_addr_zero;
                        rom_addr_one <= rom_addr_one;
                        rom_addr_two <= rom_addr_two;
                        rom_addr_three <= rom_addr_three;
                        rom_addr_four <= rom_addr_four;
                        rom_addr_enemy2 <= rom_addr_enemy2;
                        rom_addr_enemy3 <= rom_addr_enemy3;
                        rom_addr_enemy4 <= rom_addr_enemy4;
                        rom_addr_water <= rom_addr_water;
                        rom_addr_drug <= rom_addr_drug;
                        end
                end
        end
    end
    assign {vga_r,vga_g,vga_b} = vga_data;
    
    always @(posedge pclk or posedge rst)
    begin
        if(rst)
        begin
            character_x <= 0;
            character_y <= 0;
        end
        else if(level==0)
        begin
            if(nextcharacter_x==46&&nextcharacter_y==66&&box1)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==126&&nextcharacter_y==66&&box3)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==46&&nextcharacter_y==306&&box2)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==126&&nextcharacter_y==306&&box4)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==86&&nextcharacter_y==6)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if((nextcharacter_x==166||nextcharacter_x==206||nextcharacter_x==246)&&nextcharacter_y==66)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if((nextcharacter_x==6||nextcharacter_x==246)&&nextcharacter_y==126)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if((nextcharacter_x==86||nextcharacter_x==206)&&nextcharacter_y==186)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if((nextcharacter_x==86||nextcharacter_x==246)&&nextcharacter_y==246)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if((nextcharacter_x==6||nextcharacter_x==166||nextcharacter_x==286)&&nextcharacter_y==306)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if((nextcharacter_x==166||nextcharacter_x==206)&&nextcharacter_y==366)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if((nextcharacter_x==86||nextcharacter_x==246)&&nextcharacter_y==426)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==bomb1_x&&nextcharacter_y==bomb1_y)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else
            begin
                character_x <= nextcharacter_x;
                character_y <= nextcharacter_y;
            end
        end
        else if(level==1)
        begin
            if((nextcharacter_x==6||nextcharacter_x==86)&&(nextcharacter_y==246||nextcharacter_y==366))
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if((nextcharacter_x==166||nextcharacter_x==246)&&(nextcharacter_y==6||nextcharacter_y==66||nextcharacter_y==126||nextcharacter_y==186||nextcharacter_y==246||nextcharacter_y==366||nextcharacter_y==426))
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==46&&nextcharacter_y==6&&box5)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==46&&nextcharacter_y==66&&box6)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==46&&nextcharacter_y==126&&box7)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==46&&nextcharacter_y==186&&box8)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==46&&nextcharacter_y==246&&box9)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==46&&nextcharacter_y==366&&box10)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==126&&nextcharacter_y==6&&box11)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==126&&nextcharacter_y==66&&box12)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==126&&nextcharacter_y==126&&box13)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==126&&nextcharacter_y==186&&box14)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==126&&nextcharacter_y==246&&box15)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else if(nextcharacter_x==126&&nextcharacter_y==366&&box16)
            begin
                character_x <= character_x;
                character_y <= character_y;
            end
            else
            begin
                character_x <= nextcharacter_x;
                character_y <= nextcharacter_y;
            end
        end
    end
    
    always @(posedge counter[16] or posedge rst)
    begin
        if (rst) begin
           nextcharacter_x <= 10'd6;
           nextcharacter_y <= 10'd426;
       end
       else if(S0_out&&character_x!=286&&Judge==0) begin
           nextcharacter_x <= character_x + 10'd40;
           nextcharacter_y <= character_y;
       end
       else if(S3_out&&character_x!=6&&Judge==0) begin
           nextcharacter_x <= character_x - 10'd40;
           nextcharacter_y <= character_y;
       end
       else if(S4_out&&character_y!=6&&Judge==0) begin
           nextcharacter_x <= character_x;
           nextcharacter_y <= character_y - 10'd60;
       end
       else if(S2_out&&character_y!=426&&Judge==0) begin
           nextcharacter_x <= character_x;
           nextcharacter_y <= character_y + 10'd60;
       end
       else
       begin
           nextcharacter_x <= character_x;
           nextcharacter_y <= character_y;
       end
    end
    
    always @(posedge counter[16] or posedge rst)
    begin
        if(rst)
        begin
            bomb1_x <= 0;
            bomb1_y <= 0;
            bomb1_start <= 0;
        end
        else if(S1_out&&bomb1_time==0&&Judge==0) begin
            bomb1_x <= character_x;
            bomb1_y <= character_y;
            bomb1_start <= 1;
        end
        else if(!S1_out&&bomb1_time!=0)
        begin
            bomb1_start <= 0;
        end
        else if(bomb1_time==0)
        begin
            bomb1_x <= 0;
            bomb1_y <= 0;
        end
    end
    
    always @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            box1 <= 1;
            box2 <= 1;
            box3 <= 1;
            box4 <= 1;
            box5 <= 1;
            box6 <= 1;
            box7 <= 1;
            box8 <= 1;
            box9 <= 1;
            box10 <= 1;
            box11 <= 1;
            box12 <= 1;
            box13 <= 1;
            box14 <= 1;
            box15 <= 1;
            box16 <= 1;
            enemy1 <= 1;
            enemy2 <= 1;
            enemy3 <= 1;
            enemy4 <= 1;
            enemy5 <= 1;
            enemy6 <= 1;
            Judge <= 0;
            buff <= 0;
            bonus_time_bomb_add[0] <= 0;
            bonus_time_bomb_add[1] <= 0;
            bonus_time_bomb_add[2] <= 0;
            bonus_time_bomb_add[3] <= 0;
            bonus_time_bomb_add[4] <= 0;
            bonus_time_bomb_add[5] <= 0;
            bonus_time_bomb_decrease[0] <= 10'd1000;
            bonus_time_bomb_decrease[1] <= 10'd1000;
            bonus_time_bomb_decrease[2] <= 10'd1000;
            bonus_time_bomb_decrease[3] <= 10'd1000;
            bonus_time_bomb_decrease[4] <= 10'd1000;
            bonus_time_bomb_decrease[5] <= 10'd1000;
        end
        else if(level==0)
        begin
            if(bomb1_x==46&&(bomb1_y==6||bomb1_y==126)&&bomb1_time==0&&!bomb1_start)
            begin
                box1 <= 0;
            end
            if(bomb1_y==66&&(bomb1_x==6||bomb1_x==86)&&bomb1_time==0&&!bomb1_start)
            begin
                box1 <= 0;
            end
            if(bomb1_x==46&&(bomb1_y==246||bomb1_y==366)&&bomb1_time==0&&!bomb1_start)
            begin
                box2 <= 0;
            end
            if(bomb1_y==306&&(bomb1_x==6||bomb1_x==86)&&bomb1_time==0&&!bomb1_start)
            begin
                box2 <= 0;
            end
            if(bomb1_x==126&&(bomb1_y==6||bomb1_y==126)&&bomb1_time==0&&!bomb1_start)
            begin
                box3 <= 0;
            end
            if(bomb1_y==66&&(bomb1_x==86||bomb1_x==166)&&bomb1_time==0&&!bomb1_start)
            begin
                box3 <= 0;
            end
            if(bomb1_x==126&&(bomb1_y==246||bomb1_y==366)&&bomb1_time==0&&!bomb1_start)
            begin
                box4 <= 0;
            end
            if(bomb1_y==306&&(bomb1_x==86||bomb1_x==166)&&bomb1_time==0&&!bomb1_start)
            begin
                box4 <= 0;
            end
            if(((bomb1_x==46&&bomb1_y==6)||(bomb1_x==6&&bomb1_y==66))&&safe_number[1]==1&&bomb1_time==0&&!bomb1_start)
            begin
                Judge <= Failed;
            end
            if((bomb1_x==286&&bomb1_y==186)&&safe_number[0]==1&&bomb1_time==0&&!bomb1_start)
            begin
                Judge <= Failed;
            end
            if(bomb1_x==character_x&&(bomb1_y==character_y+60||bomb1_y==character_y-60)&&bomb1_time==0&&!bomb1_start)
            begin
                Judge <= Failed;
            end
            if(bomb1_y==character_y&&(bomb1_x==character_x+40||bomb1_x==character_x-40)&&bomb1_time==0&&!bomb1_start)
            begin
                Judge <= Failed;
            end
            if(safe_number==0)
            begin
                Judge <= Success;
            end
            if(ten_time==0&&one_time==0)
            begin
                Judge <= Failed;
            end
        end
        else if(level==1&&!buff)
        begin
            if(bomb1_x==46&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box5 <= 0;
            end
            if(bomb1_y==6&&(bomb1_x==6||bomb1_x==86)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box5 <= 0;
            end
            if(bomb1_x==46&&(bomb1_y==6||bomb1_y==126)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box6 <= 0;
            end
            if(bomb1_y==66&&(bomb1_x==6||bomb1_x==86)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box6 <= 0;
            end
            if(bomb1_x==46&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box7 <= 0;
            end
            if(bomb1_y==126&&(bomb1_x==6||bomb1_x==86)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box7 <= 0;
            end
            if(bomb1_x==46&&(bomb1_y==126||bomb1_y==246)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box8 <= 0;
            end
            if(bomb1_y==186&&(bomb1_x==6||bomb1_x==86)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box8 <= 0;
            end
            if(bomb1_x==46&&(bomb1_y==186||bomb1_y==306)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box9 <= 0;
            end
            if(bomb1_y==246&&(bomb1_x==6||bomb1_x==86)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box9 <= 0;
            end
            if(bomb1_x==46&&(bomb1_y==306||bomb1_y==426)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box10 <= 0;
            end
            if(bomb1_y==366&&(bomb1_x==6||bomb1_x==86)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box10 <= 0;
            end
            if(bomb1_x==126&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box11 <= 0;
            end
            if(bomb1_y==6&&(bomb1_x==86||bomb1_x==166)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box11 <= 0;
            end
            if(bomb1_x==126&&(bomb1_y==6||bomb1_y==126)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box12 <= 0;
            end
            if(bomb1_y==66&&(bomb1_x==86||bomb1_x==166)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box12 <= 0;
            end
            if(bomb1_x==126&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box13 <= 0;
            end
            if(bomb1_y==126&&(bomb1_x==86||bomb1_x==166)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box13 <= 0;
            end
            if(bomb1_x==126&&(bomb1_y==126||bomb1_y==246)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box14 <= 0;
            end
            if(bomb1_y==186&&(bomb1_x==86||bomb1_x==166)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box14 <= 0;
            end
            if(bomb1_x==126&&(bomb1_y==186||bomb1_y==306)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box15 <= 0;
            end
            if(bomb1_y==246&&(bomb1_x==86||bomb1_x==166)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box15 <= 0;
            end
            if(bomb1_x==126&&(bomb1_y==306||bomb1_y==426)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box16 <= 0;
            end
            if(bomb1_y==366&&(bomb1_x==86||bomb1_x==166)&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box16 <= 0;
            end
            if(bomb1_x==6&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind==2)
            begin
                enemy1 <= 0;
                bonus_time_bomb_add[0] <= bonus_time_bomb_add[0] + 3*enemy1;
            end
            if(bomb1_x==6&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind!=2)
            begin
                bonus_time_bomb_decrease[0] <=bonus_time_bomb_decrease[0] + 5*enemy1;
            end
            if(bomb1_x==46&&bomb1_y==6&&bomb1_time==0&&!bomb1_start&&bomb_kind==2)
            begin
                enemy1 <= 0;
                bonus_time_bomb_add[0] <= bonus_time_bomb_add[0] + 3*enemy1;
            end
            else if(bomb1_x==46&&bomb1_y==6&&bomb1_time==0&&!bomb1_start)//
            begin
                bonus_time_bomb_decrease[0] <=bonus_time_bomb_decrease[0] + 5*enemy1;
            end
            if(bomb1_x==6&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind==2)
            begin
                enemy2 <= 0;
                bonus_time_bomb_add[1] <= bonus_time_bomb_add[1] + 3*enemy2;
            end
            if(bomb1_x==6&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind!=2)
            begin
                bonus_time_bomb_decrease[1] <=bonus_time_bomb_decrease[1] + 5*enemy2;
            end
            if(bomb1_x==46&&bomb1_y==126&&bomb1_time==0&&!bomb1_start&&bomb_kind==2)
            begin
                enemy2 <= 0;
                bonus_time_bomb_add[1] <= bonus_time_bomb_add[1] + 3*enemy2;
            end
            if(bomb1_x==46&&bomb1_y==126&&bomb1_time==0&&!bomb1_start&&bomb_kind!=2)
            begin
                bonus_time_bomb_decrease[1] <=bonus_time_bomb_decrease[1] + 5*enemy2;
            end
            if(bomb1_x==206&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind==8)
            begin
                enemy3 <= 0;
                bonus_time_bomb_add[2] <= bonus_time_bomb_add[2] + 3*enemy3;
            end
            if(bomb1_x==206&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind!=8)
            begin
                bonus_time_bomb_decrease[2] <=bonus_time_bomb_decrease[2] + 5*enemy3;
            end
            if(bomb1_x==206&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind==8)
            begin
                enemy4 <= 0;
                bonus_time_bomb_add[3] <= bonus_time_bomb_add[3] + 3*enemy4;
            end
            if(bomb1_x==206&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind!=8) 
            begin
                bonus_time_bomb_decrease[3] <=bonus_time_bomb_decrease[3] + 5*enemy4;
            end
            if(bomb1_x==286&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind==4)
            begin
                enemy5 <= 0;
                bonus_time_bomb_add[4] <= bonus_time_bomb_add[4] + 3*enemy5;
            end
            if(bomb1_x==286&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind!=4)
            begin
                bonus_time_bomb_decrease[4] <=bonus_time_bomb_decrease[4] + 5*enemy5;
            end
            if(bomb1_x==286&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind==4)
            begin
                enemy6 <= 0;
                bonus_time_bomb_add[5] <= bonus_time_bomb_add[5] + 3*enemy6;
            end
            if(bomb1_x==286&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind!=4)
            begin
                bonus_time_bomb_decrease[5] <=bonus_time_bomb_decrease[5] + 5*enemy6;
            end
            if(bomb1_x==character_x&&(bomb1_y==character_y+60||bomb1_y==character_y-60)&&bomb1_time==0&&!bomb1_start)
            begin
                Judge <= Failed;
            end
            if(bomb1_y==character_y&&(bomb1_x==character_x+40||bomb1_x==character_x-40)&&bomb1_time==0&&!bomb1_start)
            begin
                Judge <= Failed;
            end
            if(drug_x==character_x&&drug_y==character_y)
            begin
                Judge <= Failed;
            end
            if(bomb1_x==drug_x&&bomb1_y==drug_y)
            begin
                Judge <= Failed;
            end
            if(character_x==286&&character_y==426&&drunk==0)
            begin
                buff <= 1;
            end
            if(ten_time==0&&one_time==0)
            begin
                Judge <= Failed;
            end
            if((enemy1 == 0)&&(enemy2 == 0)&&(enemy3 == 0)&&(enemy4 == 0)&&(enemy5 == 0)&&(enemy6 == 0))
            begin
                Judge <= Success;
            end
            if(character_x == 6&&character_y == 6 && enemy1)
            begin
                Judge <= Failed;
            end
            if(character_x == 6&&character_y == 126 && enemy2)
            begin
                Judge <= Failed;
            end
            if(character_x == 206&&character_y == 6 && enemy3)
            begin
                Judge <= Failed;
            end
            if(character_x == 206&&character_y == 126 && enemy4)
            begin
                Judge <= Failed;
            end
            if(character_x == 286&&character_y == 6 && enemy5)
            begin
                Judge <= Failed;
            end
            if(character_x == 286&&character_y == 126 && enemy6)
            begin
                Judge <= Failed;
            end
        end
        else if(level==1&&buff)
        begin
            if(bomb1_y==6&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box5 <= 0;
                box11 <= 0;
                buff <= 0;
                bonus_time_bomb_decrease[0] <=bonus_time_bomb_decrease[0] - 5*enemy1;
                bonus_time_bomb_decrease[2] <=bonus_time_bomb_decrease[2] - 5*enemy3;
                bonus_time_bomb_decrease[4] <=bonus_time_bomb_decrease[4] - 5*enemy5;
            end
            if(bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box6 <= 0;
                box12 <= 0;
                buff <= 0;
            end
            if(bomb1_y==126&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box7 <= 0;
                box13 <= 0;
                buff <= 0;
                bonus_time_bomb_decrease[1] <=bonus_time_bomb_decrease[1] - 5*enemy2;
                bonus_time_bomb_decrease[3] <=bonus_time_bomb_decrease[3] - 5*enemy4;
                bonus_time_bomb_decrease[5] <=bonus_time_bomb_decrease[5] - 5*enemy6;
            end
            if(bomb1_y==186&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box8 <= 0;
                box14 <= 0;
                buff <= 0;
            end
            if(bomb1_y==246&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box9 <= 0;
                box15 <= 0;
                buff <= 0;
            end
            if(bomb1_y==366&&bomb1_time==0&&!bomb1_start&&bomb_kind==1)
            begin
                box10 <= 0;
                box16 <= 0;
                buff <= 0;
            end
            if(bomb1_x==6&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind==2)
            begin
                enemy1 <= 0;
                buff <= 0;
                bonus_time_bomb_add[0] <= bonus_time_bomb_add[0] + 3*enemy1;
            end
            if(bomb1_x==6&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind!=2)
            begin
                buff <= 0;
                bonus_time_bomb_decrease[0] <=bonus_time_bomb_decrease[0] + 5*enemy1;
            end
            if(bomb1_y==6&&bomb1_time==0&&!bomb1_start&&bomb_kind==2)
            begin
                enemy1 <= 0;
                buff <= 0;
                bonus_time_bomb_add[0] <= bonus_time_bomb_add[0] + 3*enemy1;
                bonus_time_bomb_decrease[2] <=bonus_time_bomb_decrease[2] + 5*enemy3;
                bonus_time_bomb_decrease[4] <=bonus_time_bomb_decrease[4] + 5*enemy5;
            end
            if(bomb1_x==6&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind==2)
            begin
                enemy2 <= 0;
                buff <= 0;
                bonus_time_bomb_add[1] <= bonus_time_bomb_add[1] + 3*enemy2;
            end
            if(bomb1_x==6&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind!=2)
            begin
                buff <= 0;
                bonus_time_bomb_decrease[1] <=bonus_time_bomb_decrease[1] + 5*enemy2;
            end
            if(bomb1_y==126&&bomb1_time==0&&!bomb1_start&&bomb_kind==2)
            begin
                enemy2 <= 0;
                buff <= 0;
                bonus_time_bomb_add[1] <= bonus_time_bomb_add[1] + 3*enemy2;
                bonus_time_bomb_decrease[3] <=bonus_time_bomb_decrease[3] + 5*enemy4;
                bonus_time_bomb_decrease[5] <=bonus_time_bomb_decrease[5] + 5*enemy6;
            end
            if(bomb1_x==206&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind==8)
            begin
                enemy3 <= 0;
                buff <= 0;
                bonus_time_bomb_add[2] <= bonus_time_bomb_add[2] + 3*enemy3;
            end
            if(bomb1_x==206&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind!=8)
            begin
                buff <= 0;
                bonus_time_bomb_decrease[2] <=bonus_time_bomb_decrease[2] + 5*enemy3;
            end
            if(bomb1_y==6&&bomb1_time==0&&!bomb1_start&&bomb_kind==8)
            begin
                enemy3 <= 0;
                buff <= 0;
                bonus_time_bomb_add[2] <= bonus_time_bomb_add[2] + 3*enemy3;
                bonus_time_bomb_decrease[0] <=bonus_time_bomb_decrease[0] + 5*enemy1;
                bonus_time_bomb_decrease[4] <=bonus_time_bomb_decrease[4] + 5*enemy5;
            end
            if(bomb1_x==206&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind==8)
            begin
                enemy4 <= 0;
                buff <= 0;
                bonus_time_bomb_add[3] <= bonus_time_bomb_add[3] + 3*enemy4;
            end
            if(bomb1_x==206&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind!=8)
            begin
                buff <= 0;
                bonus_time_bomb_decrease[3] <=bonus_time_bomb_decrease[3] + 5*enemy4;
            end
            if(bomb1_y==126&&bomb1_time==0&&!bomb1_start&&bomb_kind==8)
            begin
                enemy4 <= 0;
                buff <= 0;
                bonus_time_bomb_add[3] <= bonus_time_bomb_add[3] + 3*enemy4;
                bonus_time_bomb_decrease[1] <=bonus_time_bomb_decrease[1] + 5*enemy2;
                bonus_time_bomb_decrease[5] <=bonus_time_bomb_decrease[5] + 5*enemy6;
            end
            if(bomb1_x==286&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind==4)
            begin
                enemy5 <= 0;
                buff <= 0;
                bonus_time_bomb_add[4] <= bonus_time_bomb_add[4] + 3*enemy5;
            end
            if(bomb1_x==286&&bomb1_y==66&&bomb1_time==0&&!bomb1_start&&bomb_kind!=4)
            begin
                buff <= 0;
                bonus_time_bomb_decrease[4] <=bonus_time_bomb_decrease[4] + 5*enemy5;
            end
            if(bomb1_y==6&&bomb1_time==0&&!bomb1_start&&bomb_kind==4)
            begin
                enemy5 <= 0;
                buff <= 0;
                bonus_time_bomb_add[4] <= bonus_time_bomb_add[4] + 3*enemy5;
                bonus_time_bomb_decrease[0] <=bonus_time_bomb_decrease[0] + 5*enemy1;
                bonus_time_bomb_decrease[2] <=bonus_time_bomb_decrease[2] + 5*enemy3;
            end
            if(bomb1_x==286&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind==4)
            begin
                enemy6 <= 0;
                buff <= 0;
                bonus_time_bomb_add[5] <= bonus_time_bomb_add[5] + 3*enemy6;
            end
            if(bomb1_x==286&&(bomb1_y==66||bomb1_y==186)&&bomb1_time==0&&!bomb1_start&&bomb_kind!=4)
            begin
                buff <= 0;
                bonus_time_bomb_decrease[5] <=bonus_time_bomb_decrease[5] + 5*enemy6;
            end
            if(bomb1_y==126&&bomb1_time==0&&!bomb1_start&&bomb_kind==4)
            begin
                enemy6 <= 0;
                buff <= 0;
                bonus_time_bomb_add[5] <= bonus_time_bomb_add[5] + 3*enemy6;
                bonus_time_bomb_decrease[1] <=bonus_time_bomb_decrease[1] + 5*enemy2;
                bonus_time_bomb_decrease[3] <=bonus_time_bomb_decrease[3] + 5*enemy4;
            end
            if(bomb1_y==character_y&&bomb1_time==0&&!bomb1_start)
            begin
                Judge <= Failed;
                buff <= 0;
            end
            if(drug_x==character_x&&drug_y==character_y)
            begin
                Judge <= Failed;
            end
            if(character_x == 6&&character_y == 6 && enemy1)
            begin
                Judge <= Failed;
            end
            if(character_x == 6&&character_y == 126 && enemy2)
            begin
                Judge <= Failed;
            end
            if(character_x == 206&&character_y == 6 && enemy3)
            begin
                Judge <= Failed;
            end
            if(character_x == 206&&character_y == 126 && enemy4)
            begin
                Judge <= Failed;
            end
            if(character_x == 286&&character_y == 6 && enemy5)
            begin
                Judge <= Failed;
            end
            if(character_x == 286&&character_y == 126 && enemy6)
            begin
                Judge <= Failed;
            end
            if(bomb1_x==drug_x&&bomb1_y==drug_y)
            begin
                Judge <= Failed;
            end
            if(ten_time==0&&one_time==0)
            begin
                Judge <= Failed;
            end
            if((enemy1 == 0)&&(enemy2 == 0)&&(enemy3 == 0)&&(enemy4 == 0)&&(enemy5 == 0)&&(enemy6 == 0))
            begin
                Judge <= Success;
            end
        end
    end
    
    always @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            drug_x <= 286;
            drug_y <= 306;
            position <= 0;
        end
        else if(count_time == 28'd50000000&&Judge==0)
        begin
            case(position)
            4'b0000: begin drug_x <= 246; position <= 1; end
            4'b0001: begin drug_x <= 206; position <= 2; end
            4'b0010: begin drug_x <= 166; position <= 3; end
            4'b0011: begin drug_x <= 126; position <= 4; end
            4'b0100: begin drug_x <= 86; position <= 5; end
            4'b0101: begin drug_x <= 46; position <= 6; end
            4'b0110: begin drug_x <= 6; position <= 7; end
            4'b0111: begin drug_x <= 46; position <= 8; end
            4'b1000: begin drug_x <= 86; position <= 9; end
            4'b1001: begin drug_x <= 126; position <= 10; end
            4'b1010: begin drug_x <= 166; position <= 11; end
            4'b1011: begin drug_x <= 206; position <= 12; end
            4'b1100: begin drug_x <= 246; position <= 13; end
            4'b1101: begin drug_x <= 286; position <= 0; end
            default: begin drug_x <= 286; position <= 0; end
            endcase
        end
        else
        begin
            drug_x <= drug_x;
            drug_y <= drug_y;
            position <= position;
        end
    end
    
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            drunk <= 0;
        else if(character_x==286&&character_y==426&&drunk==0&&level==1)
            drunk <= 1;
        else
            drunk <= drunk;
    end
    
    
    always @(posedge clk or posedge rst)
    begin
    if(rst)
        safe_number <= 2'b11;
    else
    begin
    if(character_x == 6 && character_y == 6 && safe_number == 2'b11)
        safe_number <= 2'b01;
    else if(character_x == 6 && character_y == 6 && safe_number == 2'b10)
        safe_number <= 2'b00;
    else if(character_x == 246 && character_y == 186 && safe_number == 2'b11)
        safe_number <= 2'b10;
    else if(character_x == 246 && character_y == 186 && safe_number == 2'b01)
        safe_number <= 2'b00;
    end
    end
    
    always @(posedge clk or posedge rst)
    begin
    if(rst)
        begin
        led_count <= 0;
        led_time <= 0;
        end
    else if(led_count == 28'd50000000 && ((Judge == Success)||(Judge == Failed)))
        begin
        led_count <= 0;
        if(led_time <= 4'd9)
        led_time <= led_time + 1;
        end
    else
        led_count <= led_count + 1;
    if(rst)
        begin
        led <= 0;
        end
    else if(Judge == Success)
    begin
    case(led_time)
    4'd0:led <= 16'b0000_0000_0000_0000;
    4'd1:led <= 16'b1000_1000_1000_1000;
    4'd2:led <= 16'b1100_1100_1100_1100;
    4'd3:led <= 16'b1110_1110_1110_1110;
    4'd4:led <= 16'b1111_1111_1111_1111;
    4'd5:led <= 16'b0111_0111_0111_0111;
    4'd6:led <= 16'b0011_0011_0011_0011;
    4'd7:led <= 16'b0001_0001_0001_0001;
    4'd8:led <= 16'b0000_0000_0000_0000;
    4'd9:led <= 16'b0000_0000_0000_0000;
    default:led <= 16'b0000_0000_0000_0000;
    endcase
    end
    else if(Judge == Failed)
    begin
    case(led_time)
    4'd0:led <= 16'b0000_0000_0000_0000;
    4'd1:led <= 16'b0000_0011_1100_0000;
    4'd2:led <= 16'b0000_1111_1111_0000;
    4'd3:led <= 16'b0011_1111_1111_1100;
    4'd4:led <= 16'b1111_1111_1111_1111;
    4'd5:led <= 16'b0011_1111_1111_1100;
    4'd6:led <= 16'b0000_1111_1111_0000;
    4'd7:led <= 16'b0000_0011_1100_0000;
    4'd8:led <= 16'b0000_0000_0000_0000;
    4'd9:led <= 16'b0000_0000_0000_0000;
    default:led <= 16'b0000_0000_0000_0000;
    endcase
    end
    end
endmodule
