import matplotlib.pyplot as plt

# Input data
# step, training loss, validation loss
data = """25	5.035200	3.357117
50	2.426500	2.163045
75	1.881300	1.906301
100	1.705000	1.840497
125	1.749700	1.781841
150	1.694200	1.720023
175	1.705500	1.661713
200	1.546200	1.628291
225	1.433000	1.595461
250	1.434700	1.606259
275	1.591000	1.611188
300	1.456900	1.621007
325	1.440100	1.624845
350	1.529800	1.631292
375	1.515300	1.624045
400	1.539300	1.601408
425	1.586000	1.601496
450	1.580900	1.587659
475	1.432700	1.591756
500	1.471800	1.596105"""

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
