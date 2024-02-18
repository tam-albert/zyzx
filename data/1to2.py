import matplotlib.pyplot as plt

# Input data
# step, training loss, validation loss
data = """25	0.883400	0.599057
50	0.421700	0.539420
75	0.423600	0.530077
100	0.388300	0.528256
125	0.400200	0.519189
150	0.376300	0.516060
175	0.424800	0.507626
200	0.348600	0.509248
225	0.332400	0.510548
250	0.436100	0.499821
275	0.350900	0.498529
300	0.394900	0.495433
325	0.378800	0.492662
350	0.338900	0.491605
375	0.346600	0.487182
400	0.305400	0.497817
425	0.370800	0.483945
450	0.360500	0.483451
475	0.359300	0.479073
500	0.312400	0.484038
525	0.386800	0.477243
550	0.326500	0.475880
575	0.336400	0.476866
600	0.385400	0.477436
625	0.387200	0.470892
650	0.376300	0.469085
675	0.378300	0.467570
700	0.323300	0.467654
725	0.392700	0.464648
750	0.394000	0.464032
775	0.386900	0.461801
800	0.341300	0.461480
825	0.311400	0.461652
850	0.359800	0.461940
875	0.310900	0.461809
900	0.309300	0.460310
925	0.349200	0.459634
950	0.344100	0.459545
975	0.325800	0.459053
1000	0.260700	0.459125"""

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