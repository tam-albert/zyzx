import matplotlib.pyplot as plt

# Input data
# step, training loss, validation loss
data = """25	2.821300	2.061742
50	1.845900	1.642996
75	1.548000	1.514281
100	1.463700	1.491024
125	1.552500	1.476754
150	1.451400	1.448805
175	1.419700	1.434840
200	1.416300	1.425210
225	1.414000	1.412485
250	1.361900	1.402501
275	1.414600	1.396014
300	1.327900	1.387997
325	1.283100	1.380778
350	1.354500	1.376001
375	1.355500	1.371205
400	1.393300	1.366162
425	1.304300	1.362402
450	1.329700	1.360121
475	1.311100	1.357845
500	1.302000	1.357235"""

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
