"use client";

import classes from "./page.module.css";

export default function Home() {
  return (
    <main className={classes.main}>
      <div className={`${classes.flex} ${classes.titleContainer}`}>
        <div className={`${classes.title} ${classes.animate}`}>
          Talk to the Terminal{" "}
          <div className={classes.gradientText}>in English</div>
        </div>
        <div className={`${classes.subTitle} ${classes.animate}`}>
          Natural language queries to supercharge your development workflow.
          Powered by offline, safe and secure AI.
        </div>
        <div className={`${classes.buttonContainer} ${classes.animate}`}>
          <button
            onClick={() => {
              console.log("github");
            }}
            className={classes.githubButton}
            style={{
              display: "flex",
              alignItems: "center",
            }}
          >
            <img
              src="/images/github.svg"
              alt="GitHub"
              style={{
                width: "30px",
                background: "white",
              }}
            />
            <div className={`${classes.black}`}>GitHub</div>
          </button>
        </div>
        <img
          src={"/images/terminal.png"}
          alt="terminal"
          className={`${classes.terminal} ${classes.animate}`}
        />
      </div>
    </main>
  );
}
