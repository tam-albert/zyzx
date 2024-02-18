"use client";

import classes from "../page.module.css";

export default function Home() {
  return (
    <main className={classes.main}>
      <div className={`${classes.flex} ${classes.titleContainer}`}>
        <div className={`${classes.title}`}>Zyzx Implementation Details</div>
        <div className={`${classes.buttonContainer}`}>
          <button
            className={classes.plainButton}
            onClick={() => {
              window.location.replace("/");
            }}
          >
            <div className={`${classes.black}`}>Back</div>
          </button>
        </div>
      </div>
    </main>
  );
}
