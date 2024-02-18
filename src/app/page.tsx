import Image from "next/image";
import classes from "./page.module.css";

export default function Home() {
  return (
    <main className={classes.main}>
      <div className={`${classes.flex} ${classes.titleContainer}`}>
        <div className={classes.title}>
          Talk to the Terminal{" "}
          <div className={classes.gradientText}>in English</div>
        </div>
        <div className={classes.subTitle}>
          Natural language queries to supercharge your development workflow.
          Powered by offline, safe and secure AI.
        </div>
      </div>
    </main>
  );
}
