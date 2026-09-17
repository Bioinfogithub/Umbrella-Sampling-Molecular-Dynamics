#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt

data = np.loadtxt("../results/pmf.xvg", comments=("@", "#"))

plt.plot(data[:, 0], data[:, 1])
plt.xlabel("Reaction coordinate (nm)")
plt.ylabel("Free energy (kJ mol$^{-1}$)")
plt.tight_layout()
plt.savefig("../results/pmf.png", dpi=300)
plt.show()
