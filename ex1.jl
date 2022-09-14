### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 1ce61c21-455a-43d3-89ef-334ce6b025af
begin
	using CSV, DataFrames

	using LinearAlgebra, PDMats
	using Optim#, ForwardDiff
	using Distributions
	using PlutoUI, PlutoTeachingTools, PlutoTest

	using Plots, StatsPlots, LaTeXStrings, ColorSchemes
	plotly()  # to avoid a temporary problem with GR making surface plots

end;

# ╔═╡ fb925eb5-0ec3-4bb3-a51c-6a4d17be3360
md"""
**Astro 497, Lab 3, Ex 1**
# Model Building I: Linear Models
"""

# ╔═╡ fcfda416-45d5-45d8-8776-2e7d2ead2bc5
TableOfContents()

# ╔═╡ 8fa2b2c0-ffa2-430e-b419-998a26ff93ae
md"""
## Overview

In this lab, we'll analyze measurements of the transit times of the planet Kepler-26b (also known as KOI 250.01) from [Holczer et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJS..225....9H/abstract).
First, we'll read the data and check that it meets our expectations.
Second, we'll develop a statistical model to describe our data based on our understanding of the astrophysics and measurement process.
We'll compute the maximum likelihood estimate for the model parameters using conventional linear algebra techniques.  This is a *very* useful and common method.
(I'd say its analogous the harmonic oscillator in physics!)
Next, we'll demonstrate how to fit the same model, but phrased as an optimization problem.
This approach opens the door to fitting much more complex models, but is more computationally expensive and introduces new caveats.
You'll think about a few of these complications (e.g., choice of initial guess, checking for convergence, precision of result).
"""

# ╔═╡ 89bd1bff-5066-4a6b-a797-b5a595d899f7
md"""
# Ingest & Validate the data
### Read the data
"""

# ╔═╡ 236a387c-7abb-4181-91d1-c60b277319fe
begin
	data_path = "data/koi250.01.csv" # Data from Mazeh et al. 2013 ApJS 208, 16 (Table 2)
	df = CSV.read(data_path, select=[:n, :t, :σₜ], DataFrame) # t is BJD-2454900
	df.σₜ ./= 24*60   # convert units of uncertainties from minutes to days
	nobs = size(df,1)
	df
end

# ╔═╡ 89fdc3f5-bb0a-4fa1-902c-f1f069c4c3af
aside(tip(md"To type unicode characters like σ, first type `\`, then the name of the character your want (e.g., 'sigma'), then press tab.  For the subscript `ₜ`, you'd type `\_t`+`TAB`."), v_offset=-180)

# ╔═╡ 34328910-30bd-40db-9c56-e8c5dd17feb8
tip(md"""What does 'x ./= a' mean?
The short answer is it divides x by a and stores the data in the memory previously used to store x.""")

# ╔═╡ 942b21c3-2636-4b6c-8e1c-4993c1645cd7
protip(md"""Now for the long answer.
First, `/` is the symbol for division, as in `x/a`.

Second, it's so common to update variables that there's a shorthand notation `x /= a` which is equivalent to `x = x/a`.

Third, if we write, `x = y` then the symbol `x` will point to the same data as stored in `y`.  If we write `x = x / a`, then the computer will divide `x` by `a`, create a new vector to hold the result and set `x` to point to the memory containing new vector.  That means that it has to allocate memory (which is generally much slower than performing arithmetic.)
Alternatively, we can write data into an existing array using the syntax `x .= y`, thereby avoiding an unnecessary memory allocation.

Fourth, when we're working with arrays rather than scalars, then we can specify element-wise arithmetic by adding a dot after a function name or before an arithmetic operator (e.g., `.+` instead of `+`).  (The difference is particularly important for multiplication when we need to distinguish between matrix-vector or matrix-matrix multiplication and element-wise multiplication.)

Fifth, If the dimensions of the two operands for an operator like `.+` or `./` don't match exactly, then Julia will see if it can 'broadcast' any scalars or dimensions with length one so that the dimensions of the two arrays match.  (If not, then you'll get an error.)

Finally, putting everything together, writing `x ./= a` is equivalent to `x .= x./a`.
 It will divide every element of the array `x` by `a` and write the result into the same memory as used for the original `x`.
""")

# ╔═╡ 5525c12c-bd94-4e73-a2f1-f80d035ceb20
md"""
### Plot the data
As seen in our previous lab, it's often a good idea to make a quick plot to help validate our dataset and to understand the characteristics of the data.
"""

# ╔═╡ 6dad7704-8ddb-4c12-8bbd-40f882307da3
scatter(df.n, df.t, yerr=df.σₜ, label=:none, xlabel="Transit #",  ylabel="Time (d)" )

# ╔═╡ c29f8a80-8b36-4763-92f9-1f272c9bba10
md"""**Q1a:**  Is this plot consistent with your expectations for measurements of a planet's transit times?"""

# ╔═╡ d63f0e0f-b427-45c5-ab00-fa7e39c48ce8
response_1a = missing

# ╔═╡ f4f756c0-3da8-4f45-9bf4-f951a42078bc
if ismissing(response_1a)
	still_missing()
end

# ╔═╡ 027fefd1-85fa-4de4-8717-1f7373343793
md"""**Q1b:**  Do you notice anything potentially concerning about the plot?  If so, describe your concerns.  Optionally, use the cell below to perform any tests to address your concerns."""

# ╔═╡ 5df94b2c-7bb5-4b86-a2d8-c46d12324600
response_1b = missing

# ╔═╡ cd0428ff-2b92-4085-b9c5-78cadadb536d
begin
	# Scratch cell for any optional calculations to check out concerns identified in Q1b.
end

# ╔═╡ 31a037c9-908f-4f05-b0dd-0776bc82164b
if ismissing(response_1b)
	still_missing()
end

# ╔═╡ 6dff470c-36cc-47bb-ba92-76013a1b7a00
md"""
# Developing an initial model
In this case, it may be tempting to rush to fitting a line to the data.
But we want to use this example as a chance to think through the process of building models.
It's often useful to divide the full model for astronomical observations into two parts:  a physical model and a measurement model.

### Physical model
In this case, our initial physical model is that a planet is orbiting a star and periodically transiting the star (as seen by Kepler).
For a planet on a constant Keplerian orbit, each transit will occur one orbital period ($P$) after the previous transit, and the times of transit will increase linearly with the transit number.
We can  write that as
$$t_n = t_0 + P \cdot n,$$
where $n$ is the transit number, and $t_0$ is the time of the $0$th transit.

### Measurement model
Astronomical measurements almost always have some measurement errors.
It can be useful to be explicit about when we're referring to the true value and when we're referring to the observed value.
For example, if we were measuring $y$, then we might write:
$y_{\rm obs} = y_{\rm true} + \epsilon,$
where $\epsilon$ is the measurement error.
By definition the true value of the measurement error ($\epsilon$) is unknown.
Typically, astronomers design the measurements such that the expected value of the measurement is equal the true value ($E[y_{\rm obs}] = y_{\rm true}$),
and characterize the distribution of the measurement errors.
One very common model/approximation is that the measurement errors follow a Normal distribution with a scale parameter, $\sigma$.
We denote that with

$\epsilon \sim \mathrm{Normal}(0,\sigma^2).$

Based on the properties of the Normal distribution,
$E[\epsilon]=0$,
$E[\epsilon^2] = \sigma^2$, and
$E[\epsilon^2/\sigma^2] = 1$.

In this case, the authors of [Holczer et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJS..225....9H/abstract) have invoked the Normal model and provided estimated measurement uncertainties, $σ_t$, for each observed transit.
For our initial model, we'll assume that's a good approximation.
"""

# ╔═╡ 3ae5b29d-5e57-44bc-a235-54a56d430623
aside(tip(md"""
Developing an effective model for those measurement uncertainties requires understanding how the data were collected and analyzed.
In this case, the actual observable is a number of electrons being excited in each pixel of a CCD chip during each integration.
Standard CCD image reduction techniques allow us to translate the number of electrons into an estimate for the number of photons hitting each pixel during each integration.
Aperture photometry was used combine fluxes in multiple pixels into a flux for the target star.
Then, time series analysis techniques were used to remove trends that were believed to be due to electronic effects, optical effects or intrinsic stellar variability.
Finally, astronomers fit a model for each individual transit and reported the best-fit values for those parameters, along with an estimate of their measurement uncertainty.
In an idealized scenario, the flux of the star at each time would be drawn from a [Poisson distribution](https://en.wikipedia.org/wiki/Poisson_distribution) with an time varying rate.
Since the number of photons observed at each time is very large, the Poisson distribution can be well approximate by a [Normal distribution](https://en.wikipedia.org/wiki/Normal_distribution).
The model for each transit light curve is a non-linear function of the transit model parameters.
Therefore, the true distribution for the measurement errors is almost certainly not perfectly Normal (even if the above assumptions and all the other steps of the data reduction pipeline were perfect).
Nevertheless, the Normal approximation is often reasonable and can greatly simplify further calculations.
Therefore, it is extremely common in astronomical data analysis.
"""))

# ╔═╡ 3db2e957-8061-42e7-a6c6-7ec4bcf8c1c1
md"""
### Creating the statistical model
We can combine the physical and measurement models above into a single statistical model.
```math
\begin{eqnarray}
t_{n,\rm obs} & = & t_{n, \rm true} + \epsilon_n \\
t_{n,\rm obs} & = & t_{0, \rm true} + P_{\rm true} \cdot n + \epsilon_n
\end{eqnarray}
```

For any values of $t_0$ and $P$, we can make a set of predictions

$t_{n,\rm pred}(t_0, P) = t_0 + P \cdot n$

and compare those predictions to the observations

$\Delta t_n(t_0, P) = t_{n,\rm obs} - t_{n,\rm pred}.$

Under a model with $N_{\rm obs}$ independent, uncorrelated measurement errors with known magnitudes ($\sigma_n$'s), the likelihood of the data is

$$\mathcal{L}(t_0, P) = \prod_{n=1}^{N_{\rm obs}} \frac{1}{\sqrt{2\pi\sigma_n^2}} \exp\left[-\frac{1}{2}\left(\frac{\Delta t_n}{σ_n}\right)^2\right].$$

It's useful to work with the log likelihood, $\ell \ \log \mathcal{L}$,

$$\ell \equiv  \log \mathcal{L} =
-\frac{1}{2} \sum_{n=1}^{N_{\rm obs}} \left\{ \left(\frac{\Delta t_n}{σ_n}\right)^2 + \log(2\pi \sigma_n^2) \right\} $$

Note that the second term in the sum does not depend on either any of the model parameters, so it can be treated as a constant.
Therefore, we can maximize the likelihood by minimizing the loss function

$${\rm loss} =  \sum_{n=1}^{N_{\rm obs}} \left(\frac{\Delta t_n}{σ_n}\right)^2$$

You may recognize this as the sum of the squared residuals normalized by their measurement uncertainties.   If the residuals are drawn from a Normal distribution with zero mean, then the loss function can be interpreted as a random variable drawn from a [$\chi^2$ distribution](https://en.wikipedia.org/wiki/Chi-squared_distribution).

If we could use the true values for $t_0$ and $P$, then $\Delta t_n = \epsilon_n$, then the expected value of the loss function would be minimized.

$$E[{\rm loss}(t_{0, \rm true}, P_{\rm true})] =  \sum_{n=1}^{N_{\rm obs}} E\left[ \left(\frac{\epsilon_n}{σ_n}\right)^2 \right] = N_{\rm obs}.$$

In practice, we don't know the true values for $t_0$ and $P$, but we can find the values $(t_{0,mle},P_{mle})$ that maximize the likelihood (or equivalently minimize the loss function).
If our model is appropriate, then $(t_{0,mle},P_{mle})$ should approach $(t_{0,\mathrm{true}},P_{\mathrm{true}})$ as we analyze more and more data.

The actual value of ${\rm loss}(t_{0,mle},P_{mle})$ could be larger or smaller than the expected value.
If we find a value much larger (or smaller) than expected (based on the $\chi^2$ distribution), then we should be very cautious about interpreting the data with our current model.
"""


# ╔═╡ 16501f6b-1bcf-4ebd-853b-adf859a35490
md"""
# Maximum Likelihood Estimator for Linear Models

Because we are working with a **linear model** and all measurement errors are assumed to be normally distributed, there is a particularly efficient way to compute the maximum likelihood estimate for the model parameters (i.e., $t_{0,mle}$ & $P_{mle}$).
Linear models are a foundational method for both astrophysics and data science, so it's worth taking the time to work through it at least once.

First, it's important to be precise what is meant by *linear model* above.
We say a model is linear if the predictions ($y_{\rm pred}$) is a linear function of the model parameters ($\theta$).

$y_{\mathrm{obs}} = \mathbf{A} \theta$

The matrix ($A$) specifying the relationship between the model parameters and the predictions is known as the **design matrix**.

In thise case,
```math
 \left[ \begin{matrix} t_{1,\rm pred}   \\ t_{2,\rm pred}  \\  \vdots  \\  t_{n_{nobs},\rm pred} \end{matrix} \right]
=
\left[ \begin{matrix}
	1 & n_1  \\
	1 & n_2 \\
    \vdots  & \vdots  \\
    1 & n_{nobs}
 \end{matrix} \right]
\left[ \begin{matrix} t_0 \\ P \end{matrix} \right].
```

While the expression for predictions with a linear model is quite simple, it can still be useful to wrap it into a function, so that it's easier to read code making predictions in this way.
"""

# ╔═╡ 9204bdae-ca8a-4873-93dd-6a9fcc663b50
"""
`predict_linear_model(A, b)`

Computes the predictions of a linear model with design matrix `A` and parameters `b`.
"""
function predict_linear_model(A::AbstractMatrix, b::AbstractVector)
	@assert size(A,2) == length(b)
	A*b
end;

# ╔═╡ 46023468-1afd-4f90-aca4-76651d05be47
aside(tip(md"Note that here we're performing matrix-vector multiplication and not element-wise multiplication."), v_offset=-150)

# ╔═╡ a55dbb82-7244-4f4d-ab50-192288da09e4
md"""
Given a linear model with design matrix $A$, observations $y_{obs}$, and Gaussian measurement uncertainties specified by the covariance matrix $\Sigma$, one can compute the **maximum likelihood estimate (MLE)** of the model parameters ($\theta$, or in this case $(t_0,P)$) given the actual observations, via the following equation

$$\theta_{mle}  = (A' {\Sigma}^{-1} A)^{-1} (A' \mathbf{\Sigma}^{-1} y_{obs}).$$

For our example, we assume that the measurement errors are independent of each other, so the covariance matrix, $\mathbf{\Sigma}$,
contains $\sigma_{t}$'s along the diagonal and zeros elsewhere (allowing for more efficient calculations than if it were an arbitrary positive definite matrix).
```math
\Sigma =
\left[ \begin{matrix}
	\sigma_1^2 & 0 & 0 & ... & 0 \\
	0 & \sigma_2^2 & 0 & ... & 0 \\
	0 & 0 & \sigma_3^2 & ... & 0 \\
    \vdots  & \vdots & \vdots & \vdots & \vdots \\
	0  & 0 & 0 & 0 & \sigma_{n_{\rm obs}}^2 \\
 \end{matrix} \right]
```

The function below performs this MLE calculation.
"""

# ╔═╡ 6dedd51a-7186-411d-8656-22b8e6bda439
"""
`calc_mle_linear_model(A, y_obs, covar)`

Computes the maximum likelihood estimator for b for the linear model
`y = A b`
where measurements errors of `y_obs` are normally distributed and have covariance `covar`.
"""
function calc_mle_linear_model(A::AbstractMatrix, y_obs::AbstractVector, covar::AbstractMatrix)
	@assert size(A,1) == length(y_obs) == size(covar,1) == size(covar,2)
	@assert size(A,2) >= 1
	(A' * (covar \ A)) \ (A' * (covar \ y_obs) )
end;

# ╔═╡ e869253c-eb0c-482c-a50d-8faeb8f73ee6
aside(
	md"""
	!!! tip "Tip:  Notations"
		The notation `A'` provides a convenient way to efficiently access the transpose of the matrix `A`.

	    The notation `b_mle = A \ y` to tell the computer to "solve the linear system $y = {\bf A} b_{mle}$ for $b_{mle}$ and store the results in the variable `b_mle`".
	""",
	v_offset=-300
)

# ╔═╡ cdbb3e70-6bb6-4618-91a0-ec358f833656
aside(
md"""!!! tip "Tip:  Numerical Linear Algebra"
       Th `A \ y` syntax does not specify which algorithm should be used to solve the linear system, so the compiler will use a set of heuristics to pick an algorithm based on the properties of $A$ and $y$.
	   If we had a very large problem, then we might need to pay more attention to the computational and memory requirements.

	Solving linear systems numerically introduces some additional challenges, particularly for large systems of equations.
	Computing the inverse of a matrix is computationally costly and can be numerically unstable.
	Therefore, one tries to avoid computing `inv(A)` whenever possible.
	Instead, one solves the matrix-vector equation using one of several algorithms that make use of a matrix factorization (QR, LU, Cholesky, etc.) without explicitly calculating the matrix inverse.
	""",
	v_offset=-100
)

# ╔═╡ b45002c3-296c-41da-8f62-39c93e170695
md"""
Now we can calculate the MLE for $t_0$ and $P$.
"""

# ╔═╡ 8e777eec-cc31-41a2-9e47-a8d14000e7eb
A = [ones(nobs) df.n] # design matrix for linear transit time model

# ╔═╡ f08d0d5d-b699-4add-b823-0ba67cfa2bd6
covar = diagm(df.σₜ.^2)  # diagm creates a diagonal matrix

# ╔═╡ ec799f18-e0bf-45c7-95ab-36f66b4b0f38
protip(md"""
We could improve the memory and computational efficiency of the calculations by telling Julia to store the covariance matrix in a type that knows the matrix is diagonal and positive definite by writing
`covar = PDiagMat(df.σₜ.^2)` (and using the [PDMats.jl](https://github.com/JuliaStats/PDMats.jl) pacakge).

Note that in both cases, we've used the "dot" version of the exponentiation operator to indicate that the computer should compute the square of every element of the array df.σₜ (i.e., this does *not* compute the dot product of the vector with itself)  For computing dot products, there's the `dot()` function or `⋅` operator.
""")

# ╔═╡ aa84c8f2-5fe4-4383-8158-53ffd30435ca
θ_mle = calc_mle_linear_model(A, df.t, covar)

# ╔═╡ 5afada56-13aa-47e4-aef8-dc886d536405
md"""
We can compute the predicted transit times using this model as $A\, \theta_{mle}$ or using our previous `predict_linear_model` function.
"""

# ╔═╡ b9234177-5bc5-4356-87ce-8bb0aee2e075
predict_linear_model(A, θ_mle)

# ╔═╡ 55e1ed7d-3418-43c6-8a4e-b2a976b6c94c
md"""
Next, we'll implement a loss function the compares the prediction of a linear model to the observed data and evaluate the loss function at the MLE.
"""

# ╔═╡ 23830bbd-3720-4dfa-ac13-c4d0228a7799
loss(θ) = sum( ((predict_linear_model(A,θ).-df.t)./df.σₜ).^2 )

# ╔═╡ f6aa766e-cee0-44c7-a412-f60c40a2c2f6
loss_at_mle = loss(θ_mle)

# ╔═╡ a471ec35-58b1-4120-85dc-58e0449b085f
let
	expected_distribution = Chisq(nobs)
	est_max_y = maximum(pdf.(expected_distribution,range(nobs/2,stop=1.5*nobs,length=100)))

	plt = plot(expected_distribution, xlabel="loss", ylabel="Probability", legend=:none)
	plot!(plt,[loss_at_mle,loss_at_mle],[0,est_max_y], linestyle=:dot, linecolor=:black)
end

# ╔═╡ 5f50ba7a-ba5d-40f4-a24f-3f5a546a3a46
md"""
**Q2a:**  How does the loss function at the MLE (vertical dotted line) compare to its expected value (mean of the distribution plotted in blue) if the model were correct?  What does that imply about the model?
"""

# ╔═╡ d62bc0f3-b858-4174-ae97-fe0f4f3cdddd
response_2a = missing

# ╔═╡ ccf63ccb-12bc-44d5-a129-1ec9545c4250
if ismissing(response_2a)
	still_missing()
end

# ╔═╡ 053bb34a-4377-4245-98cd-7acb4fba739c
protip(md"""
One can also efficiently estimate the uncertainty in the maximum likelihood estimator using the inverse of the [Fischer information matrix](https://en.wikipedia.org/wiki/Fisher_information).
(If you're curious, there's a function to estimate `σ_mle = calc_sigma_mle_linear_model(A, covar)`  at the bottom of the notebook.)
""")

# ╔═╡ e209a4d9-6449-46ae-8271-5d02f50e7533
md"""
Since the above calculations reduce to linear algebra, they are very fast (for small to moderate sized data sets like this one).  However, there are some important limitations.

**Question 2b:**  What are at least two scientific reasons why one might need a more flexible approach.
"""

# ╔═╡ 042722af-91b1-4f5e-a765-6a58e795e621
response_2b = missing

# ╔═╡ 06ab0d6e-2a01-49c0-bf8c-140c2404b5b8
if ismissing(response_2b)
	still_missing()
end

# ╔═╡ 29e1d4a0-85d0-4fea-bf10-dc084643c542
md"""
Once you've thought of at least two reasons on you can hover over the hint box below to see some additional reasons.  (You don't need to update your response to 2a based on looking at the hint.)

!!! hint "Hint"
    - What if the physical model was not linear?
    - What if we wanted to adopt a Bayesian approach and compute the maximum *a posteriori* value of $b$, $b_{map}$ (using non-Gaussian priors)?
    - What if we wanted to compute uncertainties on our model parameters that account for those priors?
	- What if we wanted to allow for measurement errors that are not drawn from a Gaussian distribution?
"""

# ╔═╡ 62a2fd8d-6479-4623-8327-8ad6bdc3f37f
md"""
## More Flexible Approaches

In order to address some of the questions raised above, we'll need approaches for building models that are more flexible and can work for non-linear models.
There are too many algorithms for us to cover them all.
(If you're interested, consider taking classes in statistics, machine learning and/or astrostatistics.)
So we'll focus on two broad classes of algorithms: Optimization and Sampling.
In this exercise, we'll start with optimization and use two common optimization algorithms.
"""

# ╔═╡ a66ebf37-6f34-4bdd-998e-a4b79f85ec00
md"""
## Optimization
One approach to model fitting is to reframe the problem from model fitting to maximizing a target function (e.g., the log likelihood, $\mathcal{L}$}).
Since many algorithms are implemented to find a minimum rather than a maximum, it's common to multiply the log likelihood by -1 and to minimize the negative log likelihood ($-\ell \equiv -\log \mathcal{L}$).
"""

# ╔═╡ cbcf77cf-d3f4-4828-ae73-eccc6d443312
protip(md"""
One advantage of the optimization approach is that it can be naturally extended to minimizing a [loss functions](https://en.wikipedia.org/wiki/Loss_function) that is not necessarily a negative log likelihood.  For example:
- In a Bayesian context, one could minimize the negative log a posteriori probability.
- One could minimize a utility function marginalized over the a posterior probability density, so as to combine information about the expected frequency and the expected cost.
- In a frequentist setting, one could add a penalty function to the negative log likelihood (a form of *regularization*), so as to enforce a preference for some parameter values.
- When using simulation-based inference, other likelihood-free methods or some machine learning method, it may be impractical to calculate (or even write down) a likelihood.  In these cases, domain experts may still formulate a sensible loss function that should be minimized.""")

# ╔═╡ 531564cf-319b-4d11-96ef-05ed9de25d34
md"""
In general, finding the minimum of an arbitrary function is a hard problem (especially as the dimension of the input variable increases).
Fortunately, log-likelihoods associated with measurements of continuous physical variables tend to be continuous and smooth.

First, let's take a look a the loss function for our current problem for fitting transit time.  (You can use your mouse to rotate the viewing angle and see level contours.)
"""

# ╔═╡ 04cdcd6f-4a74-4eaf-92c3-f9d48a9d228f
md"""
**Q3a:**  Is $t_0$ or $P$ more tightly constrained by the data?
"""

# ╔═╡ d3dbbc79-31a7-468f-b3e5-bd2947fae35a
response_3a = missing   # Set to either "t_0" or "P"

# ╔═╡ 370c695e-3517-470c-8056-a167e2ddef3d
if ismissing(response_3a)
	still_missing()
elseif typeof(response_3a) != String
	danger(md"Please set response above to a string.")
elseif !(lowercase(response_3a)∈["t_0","p"])
	danger(md"""Please set response to either `"t_0"` or `"P"`.""")
elseif lowercase(response_3a)!="p"
	keep_working(md"Look at the figure above more closely.")
else
	correct()
end

# ╔═╡ 02a61990-c020-4440-8420-5c335ef06a58
md"""
Change the number in the text box below to zoom in/out.

Scale plotting range by a factor of:
$(@bind zoom_level NumberField(1:1_000_000, default=10.0))

**Q3b:**  Does the shape of the loss function change as you zoom in/out?
"""

# ╔═╡ 98936197-bbc6-401a-bcdf-22a868ab3393
response_3b = missing  # Set to "Yes" or "No"

# ╔═╡ 042acf13-9ce0-4b5e-bc1d-7e33f7db3fe6
if ismissing(response_3b)
	still_missing()
elseif typeof(response_3b) != String
	danger(md"Please set response above to a string.")
elseif !(lowercase(response_3b)∈["yes","no"])
	danger(md"""Please set response to either `"Yes"` or `"No"`.""")
elseif lowercase(response_3b)!="no"
	keep_working(md"Look at the figure above more closely.")
else
	correct()
end

# ╔═╡ aa4f67d1-fd32-4da2-9cfa-3b4999219828
md"""
**Q3c:** How many local minima are there?
"""

# ╔═╡ c05feaba-7833-4166-a1df-841727237f8f
response_3c = missing # Set to an integer

# ╔═╡ 2d8193e9-6f69-4d76-90e0-921a09210e83
if ismissing(response_3c)
	still_missing()
elseif !(typeof(response_3c) <: Integer)
	danger(md"Please set response above to an integer.")
elseif !(response_3c==1)
	keep_working(md"Look at the figure above more closely.")
else
	correct()
end

# ╔═╡ 3ee86a8e-ef80-4b16-8056-a6daa0889e1f
md"""
**Q3d:** If you made a different (potentially poor) initial guess for the model parameters and repeatedly updated your guess to "walk downhill" (i.e., the [gradient descent algorithm](https://ml-cheatsheet.readthedocs.io/en/latest/gradient_descent.html)), the algorithm would eventually end up at a minimum of the loss funciton.  Should the point at which the algorithm converged depend on your initial guess?  Why or why not?
"""

# ╔═╡ 6047ab54-bc2f-4c1d-bf6a-5a046b44800b
response_3d = missing  

# ╔═╡ 34cab6b2-9e12-4d62-ac91-2752e09a05f6
if ismissing(response_3d)
	still_missing()
end

# ╔═╡ cec5e422-f6db-490f-a61a-77fab9ea3844
md"## Iterative Optimization Algorithms"

# ╔═╡ f76a33ca-a2ab-4c6d-b53f-1dce4735aca4
md"""
Based on visual inspection above, we've verified that our loss function is well-suited for applying an iterative optimization algorithm.
We'll start by making an initial guess for the model parameters and then use one of the optimizers provide by the [Optim.jl](https://julianlsolvers.github.io/Optim.jl/stable/) package to repeatedly improve the guess.
"""

# ╔═╡ 41e460cc-7c70-439a-9601-baf3b7babd7e
init_guess = [100.0, 10]  # [ t_{0,guess}, P_guess ] both in days

# ╔═╡ 34d2eef2-f73d-44d5-aef6-930a23b50452
result_opt_ignore_gradient = optimize(loss, init_guess )

# ╔═╡ 7b0b6ab5-49fc-498e-b57a-342c1667f4ca
md"""
We can compare the result of the iterative algorithm to the MLE estimate computed via linear algebra.
"""

# ╔═╡ a9e15b8e-6faa-495a-a2cb-43854aa3c5a9
Optim.minimizer(result_opt_ignore_gradient) .- θ_mle

# ╔═╡ 68694196-5121-4427-b12c-3deecee760d5
md"""
The above differences should be quite small, less than $10^{-8}$, indicating that the iterative method converged to very nearly the same values as the solution via linear algebra.

One key property of our loss function is that it is differentiable and smooth.  This makes it possible to apply optimization algorithms that use the gradient of $\ell$ to find the maximium likelihood solution.
"""

# ╔═╡ 99ce1441-a12f-40ed-b870-8d2db7eca63c
result_opt_use_gradient_default_stopping_criterion = optimize(loss, init_guess, method = GradientDescent(), store_trace = true, extended_trace = true )

# ╔═╡ 47573139-cdb5-42d9-82eb-ddce83118188
Optim.minimizer(result_opt_use_gradient_default_stopping_criterion) .- θ_mle

# ╔═╡ 350ee047-1b98-4a38-af8c-f4d643c080b4
md"""
On one hand, the result using the gradient descent algorithm is closer to the direct calculation of the MLE.
On the other hand, the status message above warns us that the algorithm did not converge.
What's going on?

Below we plot the discrepancy between the parameter values at the $n$-th iteration of the algorithm and their analytic estimate of the MLE.
"""

# ╔═╡ 54212229-5fd6-4496-9f79-dca75d5dab55
let
	max_iteratiosn_to_plot = 40
	res = result_opt_use_gradient_default_stopping_criterion
	n = min(Optim.iterations(res), max_iteratiosn_to_plot)
	history = reduce(hcat,Optim.x_trace(res))
	history .-= θ_mle
	plt1 = plot(1:n,log10.(abs.(history[1,1:n])), xlabel="Iteration", ylabel="log |Δt₀|", legend=:none)
	plt2 = plot(1:n,log10.(abs.(history[2,1:n])), xlabel="Iteration", ylabel="log |ΔP|", legend=:none)
	plot(plt1, plt2, layout=(2,1))
end

# ╔═╡ 109f6d30-b329-42a4-9c5d-4ab67b1f3978
md"""
We see that the algorithm rapidly improves the estimate, but subsequent progress is much slower.
By default, the optimization routine adopts a very strict set of criteria for convergence and warns us that those weren't met, so we don't make erroneous inferences.
In this case, we can use our understanding of the loss function to define a convergence criterion appropriate to our problem.  For example,
"""

# ╔═╡ 126cc007-73c6-4320-85db-a72585eafa1a
result_opt_using_gradient_and_custom_stopping_criterion = optimize(loss, init_guess, method = GradientDescent(), f_abstol = 1e-6)

# ╔═╡ 000f7c46-78b1-4d3d-8aa3-848bca838d19
Optim.minimizer(result_opt_using_gradient_and_custom_stopping_criterion) .- θ_mle

# ╔═╡ a579eeb9-f6fa-4deb-8518-2ee92639fd46
md"""
Now, we found a minimum that is is significantly more precise than the minimum found the original method (that did not use the gradient).
As a bonus, the new algorithm required roughly half as many evaluation of the loss function (and its gradient) as in the first example.
"""

# ╔═╡ 92908f88-a872-422d-a2ea-fe520f198ea9
tip(md"""
There are multiple choices for optimization algorithms (including the very popular [BFGS algoritihm](https://julianlsolvers.github.io/Optim.jl/stable/#algo/lbfgs/)) and many additional [conigurable options](https://julianlsolvers.github.io/Optim.jl/stable/#user/config/).  You may want to look into some of those once you're working on your project.
""")

# ╔═╡ 989f5bb8-6a52-4de2-ac79-e4b68e949c3c
protip(md"""
For linear models (or other relatively simple models), one could compute the gradients analytically and provide both $\ell$ and $\nabla\ell$ to an optimization algorithm.
However, computing $\nabla\ell$ analytically can be tedious and error prone (especially as the complexity of model increases).
Fortunately, we can use *automatic differentiation* (often referred to as "autodiff") to compute gradients numerically without having to work them out by hand.
""")

# ╔═╡ 5ba499bc-c899-44f7-b025-4104c8a6ff13
md"# Your turn to explore"

# ╔═╡ e673ffae-45b1-4c1d-9265-eb4df350e2fb
md"""
Soon, you'll try changing the initial guess for the model parameters.
Before you do, pause to think about what you expect to happen.

**Q4a:**  How much will the estimate of the location of the best-fit parameters change when you change your initial guess?
"""

# ╔═╡ 50249c36-0dc6-4d3f-86d6-70cb6784b1f1
response_4a = missing

# ╔═╡ c907a0b6-da98-452f-a140-e3cd9a9f4ec6
if ismissing(response_4a)
	still_missing()
end

# ╔═╡ 01c46c7f-7450-4c13-acac-6364687bf976
md"""
**Q4b:**  How will the number of iterations needed to reach convergence change (focus on using the final example outputting `result_opt_using_gradient_and_custom_stopping_criterion`)?
"""

# ╔═╡ e916c5b9-f580-4496-85d1-5e25517888ee
response_4b = missing

# ╔═╡ 75fe7d91-f41f-4dfe-b6be-1b08510442bb
if ismissing(response_4b)
	still_missing()
end

# ╔═╡ e68783c1-4b49-443c-8032-1a16051b01cf
md"""
Now go ahead and try changing the initial guess for the model parameters in the cell below.
"""

# ╔═╡ 65b8a6aa-a787-43a5-8b4e-f7b25bb1a66a
begin
	my_t0_guess = 100.0  # in days
	my_P_guess = 10.0    # in days
	my_init_guess = [my_t0_guess, my_P_guess]
	my_result = optimize(loss, my_init_guess, method = GradientDescent(), f_abstol = 1e-6, store_trace = true, extended_trace = true )
end

# ╔═╡ f4cdc7c8-fd7a-4334-a092-3fca4c001fc9
md"""
**Q4c:**  How did the results compare to your predictions?
If there are differences, what do you think could explain them?
"""

# ╔═╡ a6c6fc04-8d0a-4108-88b9-287fb77be676
response_4c = missing

# ╔═╡ 87f1cb49-3c76-46df-b76a-9731da574e18
if ismissing(response_4c)
	still_missing()
end

# ╔═╡ 582359e2-43f1-4066-9518-8db2821653a8
Optim.minimizer(my_result) .- θ_mle

# ╔═╡ b1e19f67-35b0-4d0e-8e7c-5dcbd894a7c2
Optim.f_trace(my_result)

# ╔═╡ 0c5b5130-f5ff-4be0-a43e-6d1817ed889e
md"""
## Very optional, i.e., if you're feeling ambitious:

**Q5a:**  Are the major and minor axes of the level contours nearly aligned with the $t_0$ and $P$ axes?  Or are they rotated?
"""

# ╔═╡ e957f908-1b44-4d7c-a27c-f9eec196d33b
response_5a = missing

# ╔═╡ aff494f3-dd95-473e-a03c-c69dd368f89d
md"""
**Q5b:**  How could you reparameterize the model, so that the level contours for the loss function would be nearly parallel with the axes when the loss function is written as a function of the new parameters?
"""

# ╔═╡ 56fa4fee-8a1b-415d-90a1-ecd64d723529
response_5b = missing

# ╔═╡ f694803e-6a69-40b5-853b-84f20f427c52
hint(md"""For this problem, we could have manually found a good model by just trying different combinations of values for $P$ and $t_0$.  Try your hand at finding values that minimize the residuals, $Δt$.  The values you enter in the boxes below will be stored in the variables named `P_guess` and `t₀_guess` and used in the plot below.
As you adjust increase the orbital period, how does the model prediction change (red curve in top panel?
Does this help you recognize a strategy for reparameterizing the model?
""")

# ╔═╡ aca95a73-380a-4dc1-b37f-c3d39ed7a5ff
md"""
Period: $(@bind P_guess NumberField(10.0:0.01:14, default=10.0))
t₀: $(@bind t₀_guess NumberField(90.0:0.01:110, default=90.0))
"""

# ╔═╡ baa5da8d-b26a-462f-986b-4f179f5811c6
let
	t_pred = t₀_guess .+ P_guess * df.n
	Δt = df.t .- t_pred
	χ² = sum((Δt./df.σₜ).^2)
	plt_1 =  scatter(df.n, df.t, yerr=df.σₜ, label=:none,  ylabel="t (d)")
	plot!(plt_1, df.n, t_pred, linewidth=3, label=:none )

	plt_2 = scatter(df.n, Δt, yerr=df.σₜ, label=:none, xlabel="Transit #",  ylabel="Δt (d)" )
	y_min, y_max = extrema(Δt)
	y_for_annocation = 0.8*(y_max-y_min) + y_min
	val = string(round(χ², sigdigits=2))
	annotate!(plt_2,0,y_for_annocation,"χ² = $val",:left)

	plot(plt_1, plt_2, layout=(2,1) )
end

# ╔═╡ 5ec7b223-7996-4933-860b-902417b3b83c
md"# Setup & Helper Functions"

# ╔═╡ dc8cecc4-9880-4d00-bc84-22c1e77133e7
"""
`calc_fisher_matrix_linear_model(A, covar)`

Computes the Fisher information matrix for θ for the linear model
`y = A θ`
where measurements errors of `y_obs` are normally distributed and have covariance `covar`.
Note that `y_obs` is not passed to this function, because it does not affect results.
"""
function calc_fisher_matrix_linear_model(A::AbstractMatrix, covar::AbstractMatrix)
	@assert size(A,1) == size(covar,1) == size(covar,2)
	@assert size(A,2) >= 1
	(A' * (covar \ A))
end

# ╔═╡ 8b607623-906d-44fb-b2ac-f5da061bf71d
"""
`calc_sigma_mle_linear_model(A, covar)`

Computes the uncertainty in the maximum likelihood estimate of θ for the linear model
`y = A θ`
where measurements errors of `y_obs` are normally distributed and have covariance `covar`.
Note that `y_obs` is not passed to this function, because it does not affect results.
"""
function calc_sigma_mle_linear_model(A::AbstractMatrix, covar::AbstractMatrix)
	@assert size(A,1) == size(covar,1) == size(covar,2)
	@assert size(A,2) >= 1
	sqrt.(diag(inv(PDMat(calc_fisher_matrix_linear_model(A,covar)))))
end

# ╔═╡ 0f9b4f39-aa30-4bc7-9bd7-8a0a7d2e326a
σ_mle = calc_sigma_mle_linear_model(A, covar)

# ╔═╡ 3ac58514-1a7f-4ae8-8a20-216cbc3e90bd
let
	t0_mle, period_mle = θ_mle
    x_range = range(t0_mle-zoom_level*σ_mle[1], stop=t0_mle+zoom_level*σ_mle[1], length=40)
    y_range = range(period_mle-zoom_level*σ_mle[2], stop=period_mle+zoom_level*σ_mle[2], length=40)
	plt = plot(xlabel="t₀", ylabel="P", zlabel="χ²")
	surface!(plt, x_range, y_range, (x,y)->loss([x,y]) )
end

# ╔═╡ 7170dc70-a15e-4920-ac81-1b83f12c8607
if false
	# This is the code used to create the input CSV datafile from the space delimited data file available from the AAS journal webpage.
    lines = readlines("data/koi250.txt")
	df1 = DataFrame(map(l->(;n=parse(Int,l[9:12]), t_no_ttv=parse(Float64,l[14:24]), Δt=parse(Float64,l[26:35]), σₜ=parse(Float64,l[39:43])), lines[1:end-1]))
	df1.t = df1.t_no_ttv .+ df1.Δt./(24*60)

   CSV.write("data/koi250.01.csv", df1[!, [:n, :t, :σₜ, :t_no_ttv, :Δt]])
end;

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
ColorSchemes = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Optim = "429524aa-4258-5aef-a3af-852621145aeb"
PDMats = "90014a1f-27ba-587c-ab20-58faa44d9150"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoTest = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"

[compat]
CSV = "~0.10.4"
ColorSchemes = "~3.19.0"
DataFrames = "~1.3.4"
Distributions = "~0.25.68"
LaTeXStrings = "~1.3.0"
Optim = "~1.7.1"
PDMats = "~0.11.16"
Plots = "~1.31.7"
PlutoTeachingTools = "~0.1.7"
PlutoTest = "~0.2.2"
PlutoUI = "~0.7.39"
StatsPlots = "~0.15.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.0"
manifest_format = "2.0"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "69f7020bd72f069c219b5e8c236c1fa90d2cb409"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.2.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "91ca22c4b8437da89b030f08d71db55a379ce958"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.3"

[[deps.Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[deps.ArrayInterfaceCore]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "40debc9f72d0511e12d817c7ca06a721b6423ba3"
uuid = "30b0a656-2188-435a-8636-2ec0e6a096e2"
version = "0.1.17"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "873fb188a4b9d76549b81465b1f75c82aaf59238"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.4"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "80ca332f6dcb2508adba68f22f551adb2d00a624"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.3"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "75479b7df4167267d75294d14b58244695beb2ac"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.2"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "1833bda4a027f4b2a1c984baddcf755d77266818"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.1.0"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "1fd869cc3875b57347f7027521f561cf46d1fcd8"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.19.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "d08c20eef1f2cbc6e60fd3612ac4340b89fea322"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.9"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "9be8be1d8a6f44b96482c8af52238ea7987da3e3"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.45.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "59d00b3139a9de4eb961057eabb65ac6522be954"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.4.0"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "daa21eb85147f72e41f6352a57fccea377e310a9"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "28d605d9a0ac17118fe2c5e9ce0fbb76c3ceb120"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.11.0"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "334a5896c1534bb1aa7aa2a642d30ba7707357ef"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.68"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.Extents]]
git-tree-sha1 = "5e1e4c53fa39afe63a7d356e30452249365fba99"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.1"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "ccd479984c7838684b3ac204b716c89955c76623"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+0"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "90630efff0894f8142308e334473eba54c433549"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.5.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "129b104185df66e408edd6625d480b7f9e9823a0"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.18"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "246621d23d1f43e3b9c368bf3b72b2331a27c286"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.2"

[[deps.FiniteDiff]]
deps = ["ArrayInterfaceCore", "LinearAlgebra", "Requires", "Setfield", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "5a2cff9b6b77b33b89f3d97a4d367747adce647e"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.15.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "187198a4ed8ccd7b5d99c41b69c679269ea2b2d4"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.32"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "RelocatableFolders", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "cf0a9940f250dc3cb6cc6c6821b4bf8a4286cf9c"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.66.2"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "2d908286d120c584abbe7621756c341707096ba4"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.66.2+0"

[[deps.GeoInterface]]
deps = ["Extents"]
git-tree-sha1 = "fb28b5dc239d0174d7297310ef7b84a11804dfab"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.0.1"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "GeoInterface", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "a7a97895780dab1085a97769316aa348830dc991"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.3"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "Dates", "IniFile", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "f0956f8d42a92816d2bf062f8a6a6a0ad7f9b937"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.2.1"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions", "Test"]
git-tree-sha1 = "709d864e3ed6e3545230601f94e11ebc65994641"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.11"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "d19f9edd8c34760dca2de2b503f969d8700ed288"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.4"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "64f138f9453a018c8f3562e7bae54edc059af249"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.4"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "0f960b1404abb0b244c1ece579a0ec78d056a5d1"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.15"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "9816b296736292a80b9a3200eb7fbb57aaa3917a"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.5"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "1a43be956d433b5d0321197150c2f94e16c0aaa0"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.16"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "f27132e551e959b3667d8c93eae90973225032dd"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.1.1"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "361c2b088575b07946508f135ac556751240091c"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.17"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "5d4d2d9904227b8bd66386c1138cf4d5ffa826bf"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "0.4.9"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "dedbebe234e06e1ddad435f5c6f4b85cd8ce55f7"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "2.2.2"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "41d162ae9c868218b1f3fe78cba878aa348c2d26"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.1.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "d9ab10da9de748859a7780338e1d6566993d1f25"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "6d019f5a0465522bbfdd68ecfad7f86b535d6935"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.9.0"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "50310f934e55e5ca3912fb941dec199b49ca9b68"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.2"

[[deps.NaNMath]]
git-tree-sha1 = "b086b7ea07f8e38cf122f5016af580881ac914fe"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.7"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "0e353ed734b1747fc20cd4cba0edd9ac027eff6a"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.11"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.Observables]]
git-tree-sha1 = "dfd8d34871bc3ad08cd16026c1828e271d554db9"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.1"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "1ea784113a6aa054c5ebd95945fa5e52c2f378e7"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.7"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e60321e3f2616584ff98f0a4f18d98ae6f89bbb3"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.17+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optim]]
deps = ["Compat", "FillArrays", "ForwardDiff", "LineSearches", "LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "7351d1daa3dad1bcf67c79d1ba34dd3f6136c9aa"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.7.1"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "cf494dca75a69712a72b80bc48f59dcf3dea63ec"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.16"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0044b23da09b5608b4ecacb4e5e6c6332f833a7e"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.2"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "8162b2f8547bc23876edd0c5181b27702ae58dce"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.0.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "9888e59493658e476d3073f1ce24348bdc086660"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.0"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "a19652399f43938413340b2068e11e55caa46b65"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.31.7"

[[deps.PlutoHooks]]
deps = ["InteractiveUtils", "Markdown", "UUIDs"]
git-tree-sha1 = "072cdf20c9b0507fdd977d7d246d90030609674b"
uuid = "0ff47ea0-7a50-410d-8455-4348d5de0774"
version = "0.0.5"

[[deps.PlutoLinks]]
deps = ["FileWatching", "InteractiveUtils", "Markdown", "PlutoHooks", "Revise", "UUIDs"]
git-tree-sha1 = "0e8bcc235ec8367a8e9648d48325ff00e4b0a545"
uuid = "0ff47ea0-7a50-410d-8455-4348d5de0420"
version = "0.1.5"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "LaTeXStrings", "Latexify", "Markdown", "PlutoLinks", "PlutoUI", "Random"]
git-tree-sha1 = "67c917d383c783aeadd25babad6625b834294b30"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.1.7"

[[deps.PlutoTest]]
deps = ["HypertextLiteral", "InteractiveUtils", "Markdown", "Test"]
git-tree-sha1 = "17aa9b81106e661cffa1c4c36c17ee1c50a86eda"
uuid = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
version = "0.2.2"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8d1f54886b9037091edf146b517989fc4a09efec"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.39"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "c6c0f690d0cc7caddb74cef7aa847b824a16b256"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "e7eac76a958f8664f2718508435d058168c7953d"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.3"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "22c5201127d7b243b9ee1de3b43c408879dff60f"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.3.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "Pkg", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "dad726963ecea2d8a81e26286f625aee09a91b7c"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.4.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "f94f779c94e58bf9ea243e77a37e16d9de9126bd"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.1"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "db8481cf5d6278a121184809e9eb1628943c7704"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.13"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "Requires"]
git-tree-sha1 = "38d88503f695eb0301479bc9b0d4320b378bafe5"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "0.8.2"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "5d65101b2ed17a8862c4c05639c3ddc7f3d791e1"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.8.7"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "85bc4b051546db130aeb1e8a696f1da6d4497200"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.5"

[[deps.StaticArraysCore]]
git-tree-sha1 = "5b413a57dd3cea38497d745ce088ac8592fbb5be"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.1.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "5783b877201a82fc0014cbf381e7e6eb130473a4"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.0.1"

[[deps.StatsPlots]]
deps = ["AbstractFFTs", "Clustering", "DataStructures", "DataValues", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "2b35ba790f1f823872dcf378a6d3c3b520092eac"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.15.1"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArraysCore", "Tables"]
git-tree-sha1 = "8c6ac65ec9ab781af05b08ff305ddc727c25f680"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.12"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "4ad90ab2bbfdddcae329cba59dab4a8cdfac3832"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.7"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "e59ecc5a41b000fa94423a578d29290c7266fc10"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "34db80951901073501137bdbc3d5a8e7bbd06670"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.1.2"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "fcdae142c1cfc7d89de2d11e08721d0f2f86c98a"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.6"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "58443b63fb7e465a8a7210828c91c08b92132dff"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.14+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9ebfc140cc56e8c2156a15ceac2f0302e327ac0a"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+0"
"""

# ╔═╡ Cell order:
# ╟─fb925eb5-0ec3-4bb3-a51c-6a4d17be3360
# ╟─fcfda416-45d5-45d8-8776-2e7d2ead2bc5
# ╟─8fa2b2c0-ffa2-430e-b419-998a26ff93ae
# ╟─89bd1bff-5066-4a6b-a797-b5a595d899f7
# ╠═236a387c-7abb-4181-91d1-c60b277319fe
# ╟─89fdc3f5-bb0a-4fa1-902c-f1f069c4c3af
# ╟─34328910-30bd-40db-9c56-e8c5dd17feb8
# ╟─942b21c3-2636-4b6c-8e1c-4993c1645cd7
# ╟─5525c12c-bd94-4e73-a2f1-f80d035ceb20
# ╟─6dad7704-8ddb-4c12-8bbd-40f882307da3
# ╟─c29f8a80-8b36-4763-92f9-1f272c9bba10
# ╠═d63f0e0f-b427-45c5-ab00-fa7e39c48ce8
# ╟─f4f756c0-3da8-4f45-9bf4-f951a42078bc
# ╟─027fefd1-85fa-4de4-8717-1f7373343793
# ╠═5df94b2c-7bb5-4b86-a2d8-c46d12324600
# ╠═cd0428ff-2b92-4085-b9c5-78cadadb536d
# ╟─31a037c9-908f-4f05-b0dd-0776bc82164b
# ╟─6dff470c-36cc-47bb-ba92-76013a1b7a00
# ╟─3ae5b29d-5e57-44bc-a235-54a56d430623
# ╟─3db2e957-8061-42e7-a6c6-7ec4bcf8c1c1
# ╟─16501f6b-1bcf-4ebd-853b-adf859a35490
# ╠═9204bdae-ca8a-4873-93dd-6a9fcc663b50
# ╟─46023468-1afd-4f90-aca4-76651d05be47
# ╟─a55dbb82-7244-4f4d-ab50-192288da09e4
# ╠═6dedd51a-7186-411d-8656-22b8e6bda439
# ╟─e869253c-eb0c-482c-a50d-8faeb8f73ee6
# ╟─cdbb3e70-6bb6-4618-91a0-ec358f833656
# ╟─b45002c3-296c-41da-8f62-39c93e170695
# ╠═8e777eec-cc31-41a2-9e47-a8d14000e7eb
# ╠═f08d0d5d-b699-4add-b823-0ba67cfa2bd6
# ╟─ec799f18-e0bf-45c7-95ab-36f66b4b0f38
# ╠═aa84c8f2-5fe4-4383-8158-53ffd30435ca
# ╟─5afada56-13aa-47e4-aef8-dc886d536405
# ╠═b9234177-5bc5-4356-87ce-8bb0aee2e075
# ╟─55e1ed7d-3418-43c6-8a4e-b2a976b6c94c
# ╠═23830bbd-3720-4dfa-ac13-c4d0228a7799
# ╠═f6aa766e-cee0-44c7-a412-f60c40a2c2f6
# ╟─a471ec35-58b1-4120-85dc-58e0449b085f
# ╟─5f50ba7a-ba5d-40f4-a24f-3f5a546a3a46
# ╠═d62bc0f3-b858-4174-ae97-fe0f4f3cdddd
# ╟─ccf63ccb-12bc-44d5-a129-1ec9545c4250
# ╟─053bb34a-4377-4245-98cd-7acb4fba739c
# ╠═0f9b4f39-aa30-4bc7-9bd7-8a0a7d2e326a
# ╟─e209a4d9-6449-46ae-8271-5d02f50e7533
# ╠═042722af-91b1-4f5e-a765-6a58e795e621
# ╟─06ab0d6e-2a01-49c0-bf8c-140c2404b5b8
# ╟─29e1d4a0-85d0-4fea-bf10-dc084643c542
# ╟─62a2fd8d-6479-4623-8327-8ad6bdc3f37f
# ╟─a66ebf37-6f34-4bdd-998e-a4b79f85ec00
# ╟─cbcf77cf-d3f4-4828-ae73-eccc6d443312
# ╟─531564cf-319b-4d11-96ef-05ed9de25d34
# ╟─3ac58514-1a7f-4ae8-8a20-216cbc3e90bd
# ╟─04cdcd6f-4a74-4eaf-92c3-f9d48a9d228f
# ╠═d3dbbc79-31a7-468f-b3e5-bd2947fae35a
# ╟─370c695e-3517-470c-8056-a167e2ddef3d
# ╟─02a61990-c020-4440-8420-5c335ef06a58
# ╠═98936197-bbc6-401a-bcdf-22a868ab3393
# ╟─042acf13-9ce0-4b5e-bc1d-7e33f7db3fe6
# ╟─aa4f67d1-fd32-4da2-9cfa-3b4999219828
# ╠═c05feaba-7833-4166-a1df-841727237f8f
# ╟─2d8193e9-6f69-4d76-90e0-921a09210e83
# ╟─3ee86a8e-ef80-4b16-8056-a6daa0889e1f
# ╠═6047ab54-bc2f-4c1d-bf6a-5a046b44800b
# ╟─34cab6b2-9e12-4d62-ac91-2752e09a05f6
# ╟─cec5e422-f6db-490f-a61a-77fab9ea3844
# ╟─f76a33ca-a2ab-4c6d-b53f-1dce4735aca4
# ╠═41e460cc-7c70-439a-9601-baf3b7babd7e
# ╠═34d2eef2-f73d-44d5-aef6-930a23b50452
# ╟─7b0b6ab5-49fc-498e-b57a-342c1667f4ca
# ╠═a9e15b8e-6faa-495a-a2cb-43854aa3c5a9
# ╟─68694196-5121-4427-b12c-3deecee760d5
# ╠═99ce1441-a12f-40ed-b870-8d2db7eca63c
# ╠═47573139-cdb5-42d9-82eb-ddce83118188
# ╟─350ee047-1b98-4a38-af8c-f4d643c080b4
# ╟─54212229-5fd6-4496-9f79-dca75d5dab55
# ╟─109f6d30-b329-42a4-9c5d-4ab67b1f3978
# ╠═126cc007-73c6-4320-85db-a72585eafa1a
# ╠═000f7c46-78b1-4d3d-8aa3-848bca838d19
# ╟─a579eeb9-f6fa-4deb-8518-2ee92639fd46
# ╟─92908f88-a872-422d-a2ea-fe520f198ea9
# ╟─989f5bb8-6a52-4de2-ac79-e4b68e949c3c
# ╟─5ba499bc-c899-44f7-b025-4104c8a6ff13
# ╟─e673ffae-45b1-4c1d-9265-eb4df350e2fb
# ╠═50249c36-0dc6-4d3f-86d6-70cb6784b1f1
# ╟─c907a0b6-da98-452f-a140-e3cd9a9f4ec6
# ╟─01c46c7f-7450-4c13-acac-6364687bf976
# ╠═e916c5b9-f580-4496-85d1-5e25517888ee
# ╟─75fe7d91-f41f-4dfe-b6be-1b08510442bb
# ╟─e68783c1-4b49-443c-8032-1a16051b01cf
# ╠═65b8a6aa-a787-43a5-8b4e-f7b25bb1a66a
# ╟─f4cdc7c8-fd7a-4334-a092-3fca4c001fc9
# ╠═a6c6fc04-8d0a-4108-88b9-287fb77be676
# ╟─87f1cb49-3c76-46df-b76a-9731da574e18
# ╠═582359e2-43f1-4066-9518-8db2821653a8
# ╠═b1e19f67-35b0-4d0e-8e7c-5dcbd894a7c2
# ╟─0c5b5130-f5ff-4be0-a43e-6d1817ed889e
# ╠═e957f908-1b44-4d7c-a27c-f9eec196d33b
# ╟─aff494f3-dd95-473e-a03c-c69dd368f89d
# ╠═56fa4fee-8a1b-415d-90a1-ecd64d723529
# ╟─f694803e-6a69-40b5-853b-84f20f427c52
# ╟─aca95a73-380a-4dc1-b37f-c3d39ed7a5ff
# ╟─baa5da8d-b26a-462f-986b-4f179f5811c6
# ╟─5ec7b223-7996-4933-860b-902417b3b83c
# ╠═1ce61c21-455a-43d3-89ef-334ce6b025af
# ╟─dc8cecc4-9880-4d00-bc84-22c1e77133e7
# ╟─8b607623-906d-44fb-b2ac-f5da061bf71d
# ╟─7170dc70-a15e-4920-ac81-1b83f12c8607
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002