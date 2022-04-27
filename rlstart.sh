#!/bin/bash
#2script launcning lc0 in self play mode for RL
# parameters we pass to lc0-gamegen  $1 - syzygy path $2 - openings path $3 - weights path

#cd ~/scripts/ && ./lc0-gamegen0.sh /mnt/syzygy /mnt/books/sicilian-e4c5.pgn /mnt/nets/weights_run3_781451.pb.gz

chmod 755 -R ~/scripts/lc0-gamegen0.sh
chmod 755 -R ~/scripts/lc0-gamegen1.sh
chmod 755 -R ~/scripts/lc0-gamegen2.sh
chmod 755 -R ~/scripts/lc0-gamegen3.sh

#screen -dmS rl0 bash -c '~/scripts/lc0-gamegen0.sh /mnt/syzygy /mnt/books/sicilian-e4c5.pgn /mnt/nets/40b-sicilian-low-lr/40b-sicilian-low-lr-swa-2500.pb.gz'
#screen -dmS rl1 bash -c '~/scripts/lc0-gamegen1.sh /mnt/syzygy /mnt/books/sicilian-e4c5.pgn /mnt/nets/40b-sicilian-low-lr/40b-sicilian-low-lr-swa-2500.pb.gz'
#screen -dmS rl2 bash -c '~/scripts/lc0-gamegen2.sh /mnt/syzygy /mnt/books/sicilian-e4c5.pgn /mnt/nets/40b-sicilian-low-lr/40b-sicilian-low-lr-swa-2500.pb.gz'
#screen -dmS rl3 bash -c '~/scripts/lc0-gamegen3.sh /mnt/syzygy /mnt/books/sicilian-e4c5.pgn /mnt/nets/40b-sicilian-low-lr/40b-sicilian-low-lr-swa-2500.pb.gz'
echo screen -ls
screen -ls
#echo killall screen
#killall screen

screen -dmS rl0 bash -c "~/scripts/lc0-gamegen0.sh '/mnt/syzygy' '/mnt/books/sicilian-e4c5.pgn' '$1'"
screen -dmS rl1 bash -c "~/scripts/lc0-gamegen1.sh '/mnt/syzygy' '/mnt/books/sicilian-e4c5.pgn' '$1'"
screen -dmS rl2 bash -c "~/scripts/lc0-gamegen2.sh '/mnt/syzygy' '/mnt/books/sicilian-e4c5.pgn' '$1'"
screen -dmS rl3 bash -c "~/scripts/lc0-gamegen3.sh '/mnt/syzygy' '/mnt/books/sicilian-e4c5.pgn' '$1'"

echo "   __        /\_/\                         "
echo "  / /  _____= o_o =                        "
echo " ( (_./  )_    ^__                         "
echo "  \__(____)__<___>(@) RL CLIENTS 0,1,2,3 STARTED   "

echo screen -ls
screen -ls

