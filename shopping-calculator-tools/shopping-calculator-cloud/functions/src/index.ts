/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// Reference: https://www.davidseek.com/push-notifications-with-firebase#3.-firebase-cloud-functions
// Process
// 1. Get data from the database(user, some data)
// 2. Send notification to the user

import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions";
import { onRequest } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { getMessaging } from "firebase-admin/messaging";

admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

type ExampleData = {
  id: string;
  name: string;
  description: string;
};

// This is a mock function for getting example data
// Will impliment with spabase later
function getExampleData(): Promise<ExampleData> {
  return Promise.resolve({
    id: "1",
    name: "Example",
    description: "This is an example data",
  });
}

// TODO: Replace with real Supabase fetch for user FCM token
function getUser(userID: string): { gcmToken?: string } | null {
  logger.info(`getUser called for userID: ${userID}`);
  return null;
}

function getFormatted(data: ExampleData): { [key: string]: ExampleData[] } {
  return {
    [data.id]: [data],
  };
}

function notifyUser(
  userID: string,
  taskCount: number
): Promise<string | undefined> {
  return new Promise((resolve, reject) => {
    const user = getUser(userID); // w/ spabase
    if (!user || !user.gcmToken) {
      // reject(new Error("User not found"));
      resolve(undefined);
      return;
    }
    const payload = {
      apns: {
        payload: {
          aps: {
            alert: {
              titleLocKey: "OPEN_TASKS_HEADER",
              locKey: "OPEN_TASKS_BODY",
              locArgs: [`${taskCount}`],
            },
            "mutable-content": false,
            "thread-id": "open-tasks",
            badge: taskCount,
          },
        },
      },
      token: user.gcmToken,
    };

    getMessaging()
      .send(payload)
      .then((response: string) => {
        // Handle this however you see fit.
        // The message was sent successfully.
        resolve(
          `Did send message to: ${userID} about ${taskCount} task/s ID: ${response}`
        );
      })
      .catch((error: Error) => {
        // The message was not sent.
        // You need to check the error and debug why.
        reject(error);
      });
  });
}

export const setNotificationsTrigger = onRequest(async (_, response) => {
  try {
    const data = await getExampleData();
    const convertedTasks = getFormatted(data);

    const promises: Promise<any>[] = [];
    for (let userID in convertedTasks) {
      // To get each user's tasks
      let userTasks = convertedTasks[userID];
      // And if we have at least 1 open task, add the notify call to promises
      if (userTasks.length > 0) {
        promises.push(notifyUser(userID, userTasks.length));
      }
    }

    // Resolve all notification promises after the loop completes
    const result = await Promise.all(promises);
    response.send(
      result.filter((element: string) => {
        // Filter out entries where no notification was sent (undefined/null)
        return typeof element !== "undefined" && element !== null;
      })
    );
  } catch (error) {
    // Return the error if there was one.
    response.send(error);
  }
});

export const helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", { structuredData: true });
  response.send("Hello from Firebase!");
});
