# Training

The training pipeline resides in `tf`, this requires tensorflow running on linux (Ubuntu 16.04 in this case). (It can be made to work on windows too, but it takes more effort.)

## Installation

Install the requirements under `tf/requirements.txt`. And call `./init.sh` to compile the protobuf files.

## Data preparation

In order to start a training session you first need to download training data from https://storage.lczero.org/files/training_data/. Several chunks/games are packed into a tar file, and each tar file contains an hour worth of chunks. Preparing data requires the following steps:

```
wget https://storage.lczero.org/files/training_data/training-run1--20200711-2017.tar 
#download single tar archive with training data
wget -i /content/urls.txt -P /content/storagedata/ 
#download all training tar archives from urls.txt file and store them in particular folder
tar -xzf training-run1--20200711-2017.tar # untar single tar archive into current directory, with simple tar without compression use tar -xf 
find /content/storagedata/ -name '*.tar' -exec tar -xf {} -C /content/traindata \;
# untar all .tar training files from storagedata folder into particular folder
```
For preparing urls.txt this procedure can be used:
https://storage.lczero.org/files/training_data/ open google chrome console here (cmd+alt+i for Mac OS), use console code  and copy data urls into raw.txt.
Then raw.txt can be cleared with python script.

Google chrome console code: 
```
var urls = document.getElementsByTagName('a');		
		for (url in urls) {
		    console.log ( urls[url].href );
		}
```
Python code for cleaning raw.txt and creating urls.txt:
```
infile = "raw.txt"
outfile = "urls.txt"

delete_list = ["3VM113:4", "VM113:4 ", "VM113:4"] # this waste words can vary, edit deletelist according to output from console
fin = open(infile)
fout = open(outfile, "w+") # will generate file if needed
for line in fin:
    for word in delete_list:
        line = line.replace(word, "")
    fout.write(line)
fin.close()
fout.close()
```
## Training pipeline

Now that the data is in the right format one can configure a training pipeline. This configuration is achieved through a yaml file, see `training/tf/configs/example.yaml`:

```yaml
%YAML 1.2
---
name: 'kb1-64x6'                       # ideally no spaces
gpu: 0                                 # gpu id to process on

dataset:
  num_chunks: 100000                   # newest nof chunks to parse
  train_ratio: 0.90                    # trainingset ratio
  # For separated test and train data.
  input_train: '/path/to/chunks/*/' # supports glob
  input_test: '/path/to/chunks/*/'  # supports glob
  # For a one-shot run with all data in one directory.
  # input: '/path/to/chunks/*/'

training:
    batch_size: 2048                   # training batch
    total_steps: 140000                # terminate after these steps
    test_steps: 2000                   # eval test set values after this many steps
    # checkpoint_steps: 10000          # optional frequency for checkpointing before finish
    shuffle_size: 524288               # size of the shuffle buffer
    lr_values:                         # list of learning rates
        - 0.02
        - 0.002
        - 0.0005
    lr_boundaries:                     # list of boundaries
        - 100000
        - 130000
    policy_loss_weight: 1.0            # weight of policy loss
    value_loss_weight: 1.0             # weight of value loss
    path: '/path/to/store/networks'    # network storage dir

model:
  filters: 64
  residual_blocks: 6
...
```

The configuration is pretty self explanatory, if you're new to training I suggest looking at the [machine learning glossary](https://developers.google.com/machine-learning/glossary/) by google. Now you can invoke training with the following command:

```bash
./train.py --cfg configs/example.yaml --output /tmp/mymodel.txt
```

This will initialize the pipeline and start training a new neural network. You can view progress by invoking tensorboard:

```bash
tensorboard --logdir leelalogs
```

If you now point your browser at localhost:6006 you'll see the trainingprogress as the trainingsteps pass by. Have fun!

## Restoring models

The training pipeline will automatically restore from a previous model if it exists in your `training:path` as configured by your yaml config. For initializing from a raw `weights.txt` file you can use `training/tf/net_to_model.py`, this will create a checkpoint for you.

## Supervised training

Generating trainingdata from pgn files is currently broken and has low priority, feel free to create a PR.

## Useful commands

During training we often need to do different things at the same time, there is linux utility
that helps to be more productive called screen. Screen creates terminal window we can attach and deattach, some examples:
	
	create screen:
	screen -S name
	attach to background screen:
	screen -r name
	forcefully attach screen, needed when another user already attached
	screen -Dr name
	deattach from screen and keep it running in the background:
	ctrl + a + d
	list all screens:
	screen -ls
	close screen:
	screen -S name -X quit
	close all screens:
	killall screen
	
