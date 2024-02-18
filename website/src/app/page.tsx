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
          Natural language queries that supercharge your development workflow.
          Powered by offline, safe and secure AI.
        </div>
        <div className={`${classes.buttonContainer} ${classes.animate}`}>
          <button
            onClick={() => {
              window.location.href = "https://github.com/tam-albert/copilot";
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
            <div className={`${classes.black} ${classes.ml}`}>GitHub</div>
          </button>
          <button
            onClick={() => {
              window.location.replace("/details");
            }}
            className={classes.githubButton}
            style={{
              display: "flex",
              alignItems: "center",
            }}
          >
            <img
              src="/images/info.svg"
              style={{
                width: "30px",
                backgroundColor: "white",
              }}
            />
            <div className={`${classes.black} ${classes.ml}`}>Details</div>
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
