"use client";

import classes from "../page.module.css";
import "katex/dist/katex.min.css";
import { InlineMath, BlockMath } from "react-katex";

export default function Home() {
  return (
    <main className={classes.main}>
      <div className={classes.implementationFlexContainer}>
        <div className={classes.implementationContainer}>
          <div className={`${classes.flex} ${classes.titleContainer}`}>
            <div className={`${classes.title}`}>Implementation Details</div>
            <div className={`${classes.buttonContainer}`}>
              <button
                className={classes.githubButton}
                onClick={() => {
                  window.location.replace("/");
                }}
              >
                <div className={`${classes.black}`}>Back</div>
              </button>
            </div>
          </div>
          <div className={`${classes.blogContent}`}>
            <div className={`${classes.flex}`}>
              <img
                src="/images/terminal.png"
                alt="term"
                width={700}
                className={classes.blogImage}
              ></img>
            </div>
            <p>
              Our goal with this project was to address the issue of a lack of a
              reliable GitHub copilot-like assistant in the terminal. We know
              that alternatives exist, but most are not open-source or run on
              the cloud. Our vision was an agent that could be run locally, and
              hence safely, while not sacrificing its ability to be a genuinely
              useful tool.
            </p>
            <h1>Stack</h1>
            <p>
              Our entire interface was implemented in Zig. This was a new
              experience for all of us—none of us had ever written a project of
              Zig before—but we were drawn to Zig for several reasons:
            </p>
            <ul>
              <li>
                <span className={`${classes.bold}`}>
                  Faster tooling and development, compared to C/C++.
                </span>{" "}
                Building our project on Zig was incredibly smooth; despite the
                language&apos;s relatively new status, its build ecosystem,
                language server, and more felt mature and did not become pain
                points during our project.
              </li>
              <li>
                <span className={`${classes.bold}`}>
                  Performance and safety.
                </span>{" "}
                Zig&apos;s performance and safety features were a big draw for
                us. We wanted to build a tool that was fast and safe, and Zig
                seemed like the perfect fit for this.
              </li>
              <li>
                <span className={`${classes.bold}`}>
                  As an extra challenge.
                </span>{" "}
                We also wanted to learn a new language! In the end, our team
                learned a lot by implementing server-sent events parsing from
                scratch, wrangling with different terminal emulators in a new
                language, and more.
              </li>
            </ul>
            <h1>Model</h1>
            <p>
              The LLM behind the scenes is a heavily fine-tuned Mistral
              AI&apos;s Mixtral 8x7B mixture of experts model. We chose to focus
              on this model because it is well known to be one the best, if not
              the best, generally capable models for its size.
            </p>
            <p>
              Our fine-tuning process was split into two stages. During the
              first stage, we fine tuned on{" "}
              <a
                href="https://arxiv.org/abs/1802.08979"
                target="_blank"
                rel="noreferrer"
              >
                NL2Bash
              </a>
              , a dataset of roughly 10k bash commands paired with a natural
              language description of each command.
            </p>
            <div className={classes.flex}>
              <div className={classes.flex}>
                <img
                  src="/images/1to2.png"
                  width={600}
                  className={classes.blogImage}
                />
                <i>Fig 1. First stage of fine-tuning</i>
              </div>
              <div className={classes.flex}>
                <img
                  src="/images/2to3.png"
                  width={600}
                  style={{ marginTop: "3rem" }}
                  className={classes.blogImage}
                />
                <i style={{ marginBottom: "2rem" }}>
                  Fig 2. Second stage of fine-tuning
                </i>
              </div>
            </div>
            <p className={classes.mt}>
              The results from the first stage of fine-tuning led us to believe
              that we could further improve performance with another round of
              fine-tuning. We did not have more data, so we decided to generate
              more synthetically. We concatenated together and sanitized our
              .zsh history files and used this as a &quot;high-quality&quot;
              dataset. Every single command (roughly 200) was verified by human,
              so we knew that this set of data was a good starting point for
              generating data. In conjunction with examples from the original
              training set, we fed these into GPT to generate synthetic labels,
              and also entirely new synthetic pairs of data. The result was a
              synthetic dataset of around 10k more pairs of bash commands and
              their natural language counterparts.
            </p>
            <div className={classes.flex}>
              <img
                src="/images/pipeline.png"
                width={600}
                className={classes.blogImage}
              ></img>
              <i>Fig 3. Fine-tuning pipeline</i>
            </div>
            <h2>Model Performance</h2>
            Out of curiosity, we were interested to see how our fine-tuned model
            would compare in performance to GPT3.5. To do this, we used a metric
            for evaluating bash commands in{" "}
            <a
              href="https://arxiv.org/pdf/2103.02523.pdf"
              target="_blank"
              rel="noreferrer"
            >
              NLC2CMD
            </a>
            , a friendly competition that used the{" "}
            <a
              href="https://arxiv.org/abs/1802.08979"
              target="_blank"
              rel="noreferrer"
            >
              NL2Bash
            </a>{" "}
            dataset to train models.
            <p>
              A short explantion for why this metric looks so complicated is
              that evaluating the performance of bash commands is a difficult
              task. Bash is turing-complete, meaning that the equivalence of two
              commands is undecidable. Therefore, instead of just comparing the
              outputs of the two commands, which might vary based on runtime
              rather than the correctness of the command itself, the authors
              devised a metric that would instead compare the <i>utilities</i>{" "}
              and <i>flags</i> of each command.
            </p>
            <p>
              Let <InlineMath math="U(c)_i" /> denote the{" "}
              <InlineMath math="i" />
              th utility in the command <InlineMath math="c" />. Let{" "}
              <InlineMath math="F(u)" /> be the set of flags for utility{" "}
              <InlineMath math="u" />. Then, given a prediction command{" "}
              <InlineMath math="C_{pred}" /> and a target command{" "}
              <InlineMath math="C_{ref}" />, the <i>flag score</i> is given by
              <BlockMath math="S_F^i(C_{pred}, C_{ref}) = \frac{1}{N}\left(2\times \vert F(U(C_{pred})_i)\cap F(U(C_{ref})_i)\vert - \vert F(U(C_{pred})_i)\cup F(U(C_{ref})_i)\vert\right)," />
              where <InlineMath math="N" /> is the max number of flags in either
              set. In general, the models will produce a list of predictions{" "}
              <InlineMath math="p=\langle C_{pred},\delta\rangle" />, where{" "}
              <InlineMath math="\delta" /> is the probability of the prediction
              given by the logits of each token. The probability of a single
              prediction is given by total score function
              <BlockMath math="\sum_{i=1}^T \frac{\delta}{T}\left(\mathbb{1}[U(C_{pred})_i = U(C_{ref})_i]\times \frac{(1+S_F^i(C_{pred}, C_{ref}))}{2} + \mathbb{1}[U(C_{pred})_i \neq U(C_{ref})_i]\right)," />
              where the sum is taken over all the max size of the two utility
              sets. Finally, the score over all predictions{" "}
              <InlineMath math="\mathcal{P}" /> for a single input is given by{" "}
              <InlineMath math="\max_{p\in \mathcal{P}} S(p)" />, if there is a
              single prediction for which this is positive, otherwise{" "}
              <InlineMath math="\frac{1}{\vert \mathcal{P}\vert}\sum_{p\in \mathcal{P}}S(p)." />
              The final score is given by the average score over all inputs.
            </p>
            <p>
              After calculating this result for around 20 input commands from
              the validation set, we found the following results:
            </p>
            <div className={classes.flex}>
              <img
                src="/images/results.png"
                alt="results"
                width={500}
                className={`${classes.blogImage}`}
              ></img>
              <i>Fig 4. Model results</i>
            </div>
            <p>
              Our model ended up outperforming GPT3.5! This is a promising
              result, but there are a few things to keep in mind here:{" "}
            </p>
            <ul>
              <li>
                Due to time constraints, this was a pretty small sample size, so
                we can&apos;t say for sure whether this is actually
                statistically significant. We would have liked to know if the
                authors had a good way to perform this experiment at scale; we
                ended up running through each command and collecting utilities
                and flags by hand, which was quite inefficient.
              </li>
              <li>
                While it was nice to see the improvement, this result
                shouldn&apos;t be surprising, given that we fine-tuned on a
                pretty niche task.
              </li>
              <li>
                Given more time, we would be interested in seeing whether or not
                our model improved over the two phases of fine-tuning.
              </li>
              <li>
                These numbers don&apos;t exactly match up with state-of-the-art
                that was in the paper. We suspect that this could be due to one
                of two reasons: (1) There was some uncertainty about how we
                should be calculating certain parts of the metric, e.g.,
                specific edge cases about what constitutes a `utility` or a
                `flag`, how we should be treating deviations of the same flag,
                etc. We saw some pretty high variance in the scoring metric
                based on different interpretations, and we would have liked to
                clarify some details; we&apos;re still not confident that we
                were able to recreate the experiment exactly as it was done for
                the paper. (2) These models just aren&apos;t as good. This
                wouldn&apos;t be surprising, given our limited timeframe.
              </li>
              <li>
                This metric is not exactly the best metric, because it does not
                take into account that there can be multiple reasonable ways to
                write the same command. It also doesn&apos;t test whether the
                output command even runs! The paper briefly talked about some
                ways to cover these cases; we believe it might have been
                interesting to see how our models performed under combinations
                of these metrics.
              </li>
            </ul>
            <p>
              In conclusion, we were happy to see some promising results from
              our model. There would have been a lot more to explore given more
              time, but we are proud of what we were able to accomplish in 36
              hours (:
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}
