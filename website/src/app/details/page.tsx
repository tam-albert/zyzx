"use client";

import classes from "../page.module.css";

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
              <img src="/images/terminal.png" alt="term" width={700}></img>
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
                <img src="/images/1to2.png" width={600} />
                <i>First stage of fine-tuning</i>
              </div>
              <div className={classes.flex}>
                <img
                  src="/images/2to3.png"
                  width={600}
                  style={{ marginTop: "3rem" }}
                />
                <i style={{ marginBottom: "2rem" }}>
                  Second stage of fine-tuning
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
              <img src="/images/pipeline.png" width={600}></img>
              <i>Fine-tuning pipeline</i>
            </div>

            <div>...</div>
          </div>
        </div>
      </div>
    </main>
  );
}
