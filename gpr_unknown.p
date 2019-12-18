import numpy as np
import tensorflow as tf
import tensorflow_probability as tfp
tfb = tfp.bijectors
tfd = tfp.distributions
psd_kernels = tfp.math.psd_kernels

m = 1000
n = 3
x = np.random.randn(m, n).astype(np.float32)
y = np.random.randn(m).astype(np.float32)
x_  = np.random.randn(100, n).astype(np.float32)


class GPRMatern(tf.keras.models.Model):
    def __init__(self, feature_ndims=1):
        super().__init__()
        self.kernel = psd_kernels.MaternFiveHalves()
        self.observation_noise_variance = tf.Variable(np.float32(.01), name='obs_noise_variance')

    def gprm(self, x_obs, y_obs, x):
        return tfd.GaussianProcessRegressionModel(
            kernel=self.kernel,
            index_points=x,
            observation_index_points=x_obs,
            observations=y_obs,
            observation_noise_variance=self.observation_noise_variance)

    def nll_for_train(self, x_obs, y_obs):
        gp = tfd.GaussianProcess(
            kernel=self.kernel,
            index_points=x_obs,
            observation_noise_variance=self.observation_noise_variance)
        return -tf.reduce_mean(gp.log_prob(y_obs))

class GPRExpQuad(tf.keras.models.Model):
    def __init__(self):
        super().__init__()
        self.amplitude = tf.Variable(np.float32(0.0), name='amplitude')
        self.length_scale = tf.Variable(np.float32(0.0), name='length_scale')
        self.observation_noise_variance = tf.Variable(np.float32(-5.0), name='obs_noise_variance')

    @property
    def kernel(self):
        return psd_kernels.ExponentiatedQuadratic(tf.exp(self.amplitude), tf.exp(self.length_scale))

    def nll_for_train(self, x_obs, y_obs):
        gp = tfd.GaussianProcess(
            kernel=self.kernel,
            index_points=x_obs,
            observation_noise_variance=tf.exp(self.observation_noise_variance))
        return -tf.reduce_mean(gp.log_prob(y_obs))

    def gprm(self, x_obs, y_obs, x):
        return tfd.GaussianProcessRegressionModel(
            kernel=self.kernel,
            index_points=x,
            observation_index_points=x_obs,
            observations=y_obs,
            observation_noise_variance=tf.exp(self.observation_noise_variance))

def test_model(model=GPRMatern):
    model = model()
    optimizer = tf.keras.optimizers.Adam(learning_rate=0.01)
    # model.fit(x, y, epochs=steps)
    for i in range(10):
        with tf.GradientTape() as tape:
            l = model.nll_for_train(x, y)
        g = tape.gradient(l, model.trainable_variables)
        optimizer.apply_gradients(zip(g, model.trainable_variables))
        print({x.name: x.numpy() for x in model.trainable_variables})

matern = GPRMatern()
expquad = GPRExpQuad()

test_matern = lambda : test_model(model=GPRMatern)
test_expquad = lambda : test_model(model=GPRExpQuad)

print("finished executing gpr model")