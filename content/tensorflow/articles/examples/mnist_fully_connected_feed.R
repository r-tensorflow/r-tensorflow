#' Trains and Evaluates the MNIST network using a feed dictionary.
#' 
#' See the [TensorFlow Mechanics 101](../tutorial_tensorflow_mechanics.html) tutorial for an in-depth
#' explanation of the code in this example.

library(tensorflow)

# The MNIST dataset has 10 classes, representing the digits 0 through 9.
NUM_CLASSES <- 10L

# The MNIST images are always 28x28 pixels.
IMAGE_SIZE <- 28L
IMAGE_PIXELS <- IMAGE_SIZE * IMAGE_SIZE

# Basic model parameters as external flags.
FLAGS <- flags(
  flag_numeric('learning_rate', 0.01, 'Initial learning rate.'),
  flag_integer('max_steps', 5000L, 'Number of steps to run trainer.'),
  flag_integer('hidden1', 128L, 'Number of units in hidden layer 1.'),
  flag_integer('hidden2', 32L, 'Number of units in hidden layer 2.'),
  flag_integer('batch_size', 100L, 'Batch size. Must divide evenly into the dataset sizes.'),
  flag_string('train_dir', 'MNIST-data', 'Directory to put the training data.'),
  flag_boolean('fake_data', FALSE, 'If true, uses fake data for unit testing.')
)

# input_data
input_data <- tf$contrib$learn$datasets$mnist


# Functions to builds the MNIST network.
#
# Implements the inference/loss/training pattern for model building.
#
# 1. inference() - Builds the model as far as is required for running the network
# forward to make predictions.
# 2. loss() - Adds to the inference model the layers required to generate loss.
# 3. training() - Adds to the loss model the Ops required to generate and
# apply gradients.

# Build the MNIST model up to where it may be used for inference.
#
# Args:
#   images: Images placeholder, from inputs().
#   hidden1_units: Size of the first hidden layer.
#   hidden2_units: Size of the second hidden layer.
#
# Returns:
#   softmax_linear: Output tensor with the computed logits.
#
inference <- function(images, hidden1_units, hidden2_units) {
  
  # Hidden 1
  with(tf$name_scope('hidden1'), {
    weights <- tf$Variable(
      tf$truncated_normal(shape(IMAGE_PIXELS, hidden1_units),
                          stddev = 1.0 / sqrt(IMAGE_PIXELS)),
      name = 'weights'
    )
    biases <- tf$Variable(tf$zeros(shape(hidden1_units),
                                   name = 'biases'))
    hidden1 <- tf$nn$relu(tf$matmul(images, weights) + biases)
  })
  
  # Hidden 2
  with(tf$name_scope('hidden2'), {
    weights <- tf$Variable(
      tf$truncated_normal(shape(hidden1_units, hidden2_units),
                          stddev = 1.0 / sqrt(hidden1_units)),
      name = 'weights')
    biases <- tf$Variable(tf$zeros(shape(hidden2_units)),
                          name = 'biases')
    hidden2 <- tf$nn$relu(tf$matmul(hidden1, weights) + biases)
  })
  
  # Linear
  with(tf$name_scope('softmax_linear'), {
    weights <- tf$Variable(
      tf$truncated_normal(shape(hidden2_units, NUM_CLASSES),
                          stddev = 1.0 / sqrt(hidden2_units)),
      name = 'weights')
    biases <- tf$Variable(tf$zeros(shape(NUM_CLASSES)),
                          name = 'biases')
    logits <- tf$matmul(hidden2, weights) + biases
  })
  
  # return logits
  logits
}

# Calculates the loss from the logits and the labels.
#
# Args:
#   logits: Logits tensor, float - [batch_size, NUM_CLASSES].
#   labels: Labels tensor, int32 - [batch_size].
#
# Returns:
#   loss: Loss tensor of type float.
#
loss <- function(logits, labels) {
  labels <- tf$to_int64(labels)
  cross_entropy <- tf$nn$sparse_softmax_cross_entropy_with_logits(
    logits = logits, labels = labels, name = 'xentropy')
  tf$reduce_mean(cross_entropy, name = 'xentropy_mean')
}

# Sets up the training Ops.
#
# Creates a summarizer to track the loss over time in TensorBoard.
#
# Creates an optimizer and applies the gradients to all trainable variables.
#
# The Op returned by this function is what must be passed to the
# `sess.run()` call to cause the model to train.
#
# Args:
#   loss: Loss tensor, from loss().
#   learning_rate: The learning rate to use for gradient descent.
#
# Returns:
#   train_op: The Op for training.
#
training <- function(loss, learning_rate) {
  
  # Add a scalar summary for the snapshot loss.
  tf$summary$scalar(loss$op$name, loss)
  
  # Create the gradient descent optimizer with the given learning rate.
  optimizer <- tf$train$GradientDescentOptimizer(learning_rate)
  
  # Create a variable to track the global step.
  global_step <- tf$Variable(0L, name = 'global_step', trainable = FALSE)
  
  # Use the optimizer to apply the gradients that minimize the loss
  # (and also increment the global step counter) as a single training step.
  optimizer$minimize(loss, global_step = global_step)
}

# Evaluate the quality of the logits at predicting the label.
#
# Args:
#   logits: Logits tensor, float - [batch_size, NUM_CLASSES].
#   labels: Labels tensor, int32 - [batch_size], with values in the
#           range [0, NUM_CLASSES).
#
# Returns:
#   A scalar int32 tensor with the number of examples (out of batch_size)
#   that were predicted correctly.
evaluation <- function(logits, labels) {
  
  # For a classifier model, we can use the in_top_k Op.
  # It returns a bool tensor with shape [batch_size] that is true for
  # the examples where the label is in the top k (here k=1)
  # of all logits for that example.
  correct <- tf$nn$in_top_k(logits, labels, 1L)
  tf$reduce_sum(tf$cast(correct, tf$int32))
}

# Generate placeholder variables to represent the input tensors.
#
# These placeholders are used as inputs by the rest of the model building
# code and will be fed from the downloaded data in the .run() loop, below.
#
# Args:
#   batch_size: The batch size will be baked into both placeholders.
#
# Returns:
#   placeholders$images: Images placeholder.
#   placeholders$labels: Labels placeholder.
#
placeholder_inputs <- function(batch_size) {

  # Note that the shapes of the placeholders match the shapes of the full
  # image and label tensors, except the first dimension is now batch_size
  # rather than the full size of the train or test data sets.
  images <- tf$placeholder(tf$float32, shape(batch_size, IMAGE_PIXELS))
  labels <- tf$placeholder(tf$int32, shape(batch_size))

  # return both placeholders
  list(images = images, labels = labels)
}

# Fills the feed_dict for training the given step.
#
# A feed_dict takes the form of:
#   feed_dict = dict(
#     <placeholder = <tensor of values to be passed for placeholder>,
#     ....
#   )
#
# Args:
#   data_set: The set of images and labels, from input_data.read_data_sets()
#   images_pl: The images placeholder, from placeholder_inputs().
#   labels_pl: The labels placeholder, from placeholder_inputs().
#
# Returns:
#   feed_dict: The feed dictionary mapping from placeholders to values.
#
fill_feed_dict <- function(data_set, images_pl, labels_pl) {
  # Create the feed_dict for the placeholders filled with the next
  # `batch size` examples.
  batch <- data_set$next_batch(FLAGS$batch_size, FLAGS$fake_data)
  images_feed <- batch[[1]]
  labels_feed <- batch[[2]]
  dict(
    images_pl = images_feed,
    labels_pl = labels_feed
  )
}

# Runs one evaluation against the full epoch of data.
#
# Args:
#   sess: The session in which the model has been trained.
#   eval_correct: The Tensor that returns the number of correct predictions.
#   images_placeholder: The images placeholder.
#   labels_placeholder: The labels placeholder.
#   data_set: The set of images and labels to evaluate,
#             from input_data.read_data_sets().
#
do_eval <- function(sess,
                    eval_correct,
                    images_placeholder,
                    labels_placeholder,
                    data_set) {
  # And run one epoch of eval.
  true_count <- 0  # Counts the number of correct predictions.
  steps_per_epoch <- data_set$num_examples %/% FLAGS$batch_size
  num_examples <- steps_per_epoch * FLAGS$batch_size
  for (step in 1:steps_per_epoch) {
    feed_dict <- fill_feed_dict(data_set,
                                images_placeholder,
                                labels_placeholder)
    true_count <- true_count + sess$run(eval_correct, feed_dict=feed_dict)
  }

  precision <- true_count / num_examples
  cat(sprintf('  Num examples: %d  Num correct: %d  Precision @ 1: %0.04f\n',
              num_examples, true_count, precision))
}


# Train MNIST for a number of steps.

# Get the sets of images and labels for training, validation, and
# test on MNIST.
data_sets <- input_data$read_data_sets(FLAGS$train_dir, FLAGS$fake_data)

# Tell TensorFlow that the model will be built into the default Graph.
with(tf$Graph()$as_default(), {

  # Generate placeholders for the images and labels.
  placeholders <- placeholder_inputs(FLAGS$batch_size)

  # Build a Graph that computes predictions from the inference model.
  logits <- inference(placeholders$images, FLAGS$hidden1, FLAGS$hidden2)

  # Add to the Graph the Ops for loss calculation.
  loss <- loss(logits, placeholders$labels)

  # Add to the Graph the Ops that calculate and apply gradients.
  train_op <- training(loss, FLAGS$learning_rate)

  # Add the Op to compare the logits to the labels during evaluation.
  eval_correct <- evaluation(logits, placeholders$labels)

  # Build the summary Tensor based on the TF collection of Summaries.
  summary <- tf$summary$merge_all()

  # Add the variable initializer Op.
  init <- tf$global_variables_initializer()

  # Create a saver for writing training checkpoints.
  saver <- tf$train$Saver()

  # Create a session for running Ops on the Graph.
  sess <- tf$Session()

  # Instantiate a SummaryWriter to output summaries and the Graph.
  summary_writer <- tf$summary$FileWriter(FLAGS$train_dir, sess$graph)

  # And then after everything is built:

  # Run the Op to initialize the variables.
  sess$run(init)

  # Start the training loop.
  for (step in 1:FLAGS$max_steps) {

    start_time <- Sys.time()

    # Fill a feed dictionary with the actual set of images and labels
    # for this particular training step.
    feed_dict <- fill_feed_dict(data_sets$train,
                                placeholders$images,
                                placeholders$labels)

    # Run one step of the model.  The return values are the activations
    # from the `train_op` (which is discarded) and the `loss` Op.  To
    # inspect the values of your Ops or variables, you may include them
    # in the list passed to sess.run() and the value tensors will be
    # returned in the tuple from the call.
    values <- sess$run(list(train_op, loss), feed_dict = feed_dict)
    loss_value <- values[[2]]

    duration <- Sys.time() - start_time

    # Write the summaries and print an overview fairly often.
    if (step %% 100 == 0) {
      # Print status to stdout.
      cat(sprintf('Step %d: loss = %.2f (%.3f sec)\n',
                  step, loss_value, duration))
      # Update the events file.
      summary_str <- sess$run(summary, feed_dict=feed_dict)
      summary_writer$add_summary(summary_str, step)
      summary_writer$flush()
    }

    # Save a checkpoint and evaluate the model periodically.
    if ((step + 1) %% 1000 == 0 || (step + 1) == FLAGS$max_steps) {
      checkpoint_file <- file.path(FLAGS$train_dir, 'checkpoint')
      saver$save(sess, checkpoint_file, global_step=step)
      # Evaluate against the training set.
      cat('Training Data Eval:\n')
      do_eval(sess,
              eval_correct,
              placeholders$images,
              placeholders$labels,
              data_sets$train)
      # Evaluate against the validation set.
      cat('Validation Data Eval:\n')
      do_eval(sess,
              eval_correct,
              placeholders$images,
              placeholders$labels,
              data_sets$validation)
      # Evaluate against the test set.
      cat('Test Data Eval:\n')
      do_eval(sess,
              eval_correct,
              placeholders$images,
              placeholders$labels,
              data_sets$test)
    }
  }
})


