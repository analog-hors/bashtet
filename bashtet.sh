#!/usr/bin/env bash

piece_indexes="JLSTZIO"
pieces_x_values=(-1 -1 0 1 -1 0 1 1 -1 0 0 1 -1 0 0 1 -1 0 0 1 -1 0 1 2 0 0 1 1)
pieces_y_values=(1 0 0 0 0 0 1 0 0 1 0 1 0 1 0 0 1 1 0 0 0 0 0 0 1 0 1 0)
rotations=("north" "east" "south" "west")
o_x_offsets=(0 0 -1 -1)
o_y_offsets=(0 -1 -1 0)
i_x_offsets=(0 -1 -1 0)
i_y_offsets=(0 0 1 1)

str_field() {
    grep -oP "(?<=\"$1\":\")\w*"
}

gen_moves() {
    for piece in "$@"; do
        prefix=${piece_indexes%%$piece*}
        index=$((${#prefix} * 4))
        piece_x_values=("${pieces_x_values[@]:index:4}")
        piece_y_values=("${pieces_y_values[@]:index:4}")
        for r in "${!rotations[@]}"; do
            for x in {0..9}; do
                for y in {0..7}; do
                    if [ "$piece" = "O" ]; then
                        ((x+=o_x_offsets[r]))
                        ((y+=o_y_offsets[r]))
                    elif [ "$piece" = "I" ]; then
                        ((x+=i_x_offsets[r]))
                        ((y+=i_y_offsets[r]))
                    fi
                    new_board=("${board[@]}")
                    grounded=false
                    for i in {0..3}; do
                        ((cell_y=y+piece_y_values[i]))
                        ((cell_x=x+piece_x_values[i]))
                        if ((cell_y < 0 || cell_x < 0 || cell_x >= 10)); then
                            continue 2
                        fi
                        if [ "${new_board[cell_y]:cell_x:1}" != "n" ]; then
                            continue 2
                        fi
                        if [ $cell_y == 0 ] || [ "${new_board[cell_y-1]:cell_x:1}" != "n" ]; then
                            grounded=true
                        fi
                        new_board[$cell_y]="${new_board[cell_y]:0:cell_x}O${new_board[cell_y]:cell_x+1}"
                    done
                    if [ $grounded == false ]; then
                        continue
                    fi
                    cleared_board=()
                    cleared=40
                    for row in "${new_board[@]}"; do
                        if [[ "$row" == *"n"* ]]; then
                            cleared_board+=("$row")
                            ((--cleared))
                        fi
                    done
                    holes=0
                    total_height=0
                    bumpiness=0
                    prev_height=-1
                    for sx in {0..9}; do
                        height=0
                        for ((sy=${#cleared_board[@]}-1; sy>=0; sy--)); do
                            if [ "${cleared_board[sy]:sx:1}" != "n" ]; then
                                if ((sy >= height)); then
                                    ((height=sy+1))
                                    ((total_height+=height))
                                fi
                            elif ((sy < height)); then
                                ((++holes))
                            fi
                        done
                        if [ $prev_height != -1 ]; then
                            if ((prev_height > height)); then
                                ((bumpiness+=prev_height-height))
                            else
                                ((bumpiness+=height-prev_height))
                            fi
                        fi
                        prev_height=$height
                    done
                    ((score=total_height*-510+cleared*761+holes*-357+bumpiness*-184))
                    echo "{\"spin\":\"none\",\"location\":{\"type\":\"$piece\",\"orientation\":\"${rotations[r]}\",\"x\":$x,\"y\":$y}};$score"
                done
            done
            for i in {0..3}; do
                ((y=-${piece_x_values[i]}))
                piece_x_values[i]=${piece_y_values[i]}
                piece_y_values[i]=$y
            done
        done
    done
}

echo '{"type":"info","name":"Bashtet","version":"1","author":"Analog Hors","features":[]}'
read msg
echo '{"type":"ready"}'
sed -uE "s/\s+//g" | while read msg; do
    case $(str_field "type" <<< "$msg" | grep -E "^(start|stop|suggest|play|new_piece|quit)$") in
        "start")
            hold=$(str_field "hold" <<< "$msg")
            queue=($(grep -oP "(?<=\"queue\":\[)[\w\"\,]*" <<< "$msg" | sed "s/,/ /g" | xargs))
            board=($(grep -oP "(?<=\"board\":\[\[)[\[\"\w,\]]*(?=\]\])" <<< "$msg" | sed -e "s/\],\[/ /g" -e "s/[\",ul]//g"))
            ;;
        "suggest")
            pieces=("${queue[0]}")
            if [ -n "$hold" ]; then
                pieces+=("$hold")
            elif [ -n "${queue[1]}" ]; then
                pieces+=("${queue[1]}")
            fi
            moves=$(gen_moves "${pieces[@]}" | sort -t ";" -k 2 -n -r | cut -d ";" -f 1 | paste -sd "," -)
            echo "{\"type\":\"suggestion\",\"moves\":[$moves]}"
            ;;
        "play")
            piece_x=$(grep -oP "(?<=\"x\":)\d*" <<< "$msg")
            piece_y=$(grep -oP "(?<=\"y\":)\d*" <<< "$msg")
            rot=$(str_field "orientation" <<< "$msg")
            piece=$(str_field "type" <<< "$msg" | grep -v ".\{2,\}")
            prefix=${piece_indexes%%$piece*}
            index=$(( ${#prefix} * 4 ))
            piece_x_values=("${pieces_x_values[@]:index:4}")
            piece_y_values=("${pieces_y_values[@]:index:4}")
            for r in "${rotations[@]}"; do
                if [ "$r" = "$rot" ]; then
                    for i in {0..3}; do
                        cell_y=$(( $piece_y + ${piece_y_values[i]} ))
                        cell_x=$(( $piece_x + ${piece_x_values[i]} ))
                        board[$cell_y]=${board[$cell_y]:0:cell_x}O${board[$cell_y]:cell_x+1}
                    done
                fi
                for i in {0..3}; do
                    y=$(( -${piece_x_values[i]} ))
                    piece_x_values[i]=${piece_y_values[i]}
                    piece_y_values[i]=$y
                done
            done
            cleared_board=()
            empty_rows=()
            for row in "${board[@]}"; do
                if [[ "$row" == *"n"* ]]; then
                    cleared_board+=("$row")
                else
                    empty_rows+=("nnnnnnnnnn")
                fi
            done
            board=("${cleared_board[@]}" "${empty_rows[@]}")
            if [ "${queue[0]}" != "$piece" ]; then
                hold=${queue[0]}
            fi
            queue=("${queue[@]:1}")
            ;;
        "new_piece")
            queue+=($(str_field "piece" <<< "$msg"))
            ;;
        "quit")
            exit
            ;;
    esac
done
