import matplotlib.pyplot as plt

# Input data
# step, training loss, validation loss
data = """25	2.857500	1.846487
50	1.076200	1.102981
75	0.760000	0.807342
100	0.623100	4.800373
125	0.871900	0.694432
150	0.514400	0.643339
175	0.560900	0.641982
200	0.488400	0.624331
225	0.435600	0.637454
250	0.579700	0.582857
275	0.579100	0.765172
300	0.743100	0.798714
325	0.605900	0.750567"""

# Parsing the data
lines = data.split("\n")
x = []
train_loss = []
validation_loss = []
for line in lines:
    parts = line.split()
    x.append(float(parts[0]))
    train_loss.append(float(parts[1]))
    validation_loss.append(float(parts[2]))

# Plotting
plt.plot(x, train_loss, label="training")
plt.plot(x, validation_loss, label="validation")
plt.xlabel("step")
plt.ylabel("loss")
plt.title("loss vs. time")
plt.legend()
plt.show()
