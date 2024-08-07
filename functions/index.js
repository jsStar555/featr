/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

//const { initializeApp } =require("firebase/app");
require("dotenv").config();
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
console.log("process.env.STRIPE_SECRET_KEY ", process.env.STRIPE_SECRET_KEY);
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started
// const firebaseConfig = {
//     apiKey: "AIzaSyBDsIY-l1JTcCAP3yX5Y4fmvfAreGjFnQM",
//     authDomain: "featchr-dev.firebaseapp.com",
//     projectId: "featchr-dev",
//     storageBucket: "featchr-dev.appspot.com",
//     messagingSenderId: "565537822602",
//     appId: "1:565537822602:web:fbc0f57183374b1b399a73",
//     measurementId: "G-16E0JC949C"
// };
const firebaseConfig = {
  apiKey: "AIzaSyCU5BXNthq-wQj4gdU2vA9slm3Rlkn1clY",
  authDomain: "featchr-113f6.firebaseapp.com",
  projectId: "featchr-113f6",
  storageBucket: "featchr-113f6.appspot.com",
  messagingSenderId: "376908639577",
  appId: "1:376908639577:web:5927243e572e4fc01af048",
  measurementId: "G-4ZGVB5S0MF",
};
// Initialize Firebase
const app = admin.initializeApp(firebaseConfig);
const fireStore = app.firestore();
console.log("fireStore ", fireStore);
function extractToken(req) {
  if (
    req.headers.authorization &&
    req.headers.authorization.split(" ")[0] === "Bearer"
  ) {
    return req.headers.authorization.split(" ")[1];
  } else if (req.query && req.query.token) {
    return req.query.token;
  }
  return null;
}
function generateCustomString(length) {
  const characters =
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  let customString = "";

  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * characters.length);
    customString += characters.charAt(randomIndex);
  }

  return customString;
}
// Function to get user data based on userId
async function getUserData(userId) {
  const userDoc = await fireStore.collection("users").doc(userId).get();
  return userDoc.data();
}

// Function to get jobs data based on jobId
async function getJobData(jobsId) {
  const jobDoc = await fireStore.collection("jobs").doc(jobsId).get();
  return jobDoc.data();
}

// Firebase Cloud Function to create pending payment request
exports.createPendingPaymentRequest = onRequest(async (req, res) => {
  try {
    const { sellerId, buyerId, jobId, price } = req.body;

    // Validate the presence of required parameters
    if (!sellerId || !buyerId || !jobId || !price) {
      return res.status(400).json({
        success: false,
        message: "Missing required parameters in the request body.",
      });
    }

    // Create a reference to the "pendingPayments" collection
    const pendingPaymentsCollection = fireStore.collection("pendingPayments");

    // Create a new document in the "pendingPayments" collection
    const newPendingPaymentDocRef = await pendingPaymentsCollection.add({
      sellerId: sellerId,
      buyerId: buyerId,
      jobId: jobId,
      price: price,
      status: "pending",
    });

    return res.status(200).json({
      success: true,
      message: "Pending payment request created successfully.",
      pendingPaymentId: newPendingPaymentDocRef.id,
    });
  } catch (err) {
    console.error("Error creating pending payment request: ", err);
    res.status(500).json({ error: err.message });
  }
});

// Firebase Cloud Function to fetch all pending payments
exports.getAllPendingPayments = onRequest(async (req, res) => {
  try {
    // Extract userId from query parameters
    const userId = req.query.userId;

    // Validate the presence of the userId query parameter
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "Missing userId query parameter.",
      });
    }

    // Create a reference to the "pendingPayments" collection
    const pendingPaymentsCollection = fireStore.collection("pendingPayments");

    // Fetch documents from the "pendingPayments" collection where buyerId matches userId and status is "pending"
    const snapshot = await pendingPaymentsCollection
      .where("buyerId", "==", userId)
      .where("status", "==", "pending")
      .get();

    // Convert documents to an array
    const pendingPaymentsArray = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      pendingPaymentsArray.push({
        id: doc.id,
        sellerId: data.sellerId,
        buyerId: data.buyerId,
        jobId: data.jobId,
        price: data.price,
        status: data.status,
      });
    });
    let results = await Promise.allSettled(
      pendingPaymentsArray?.map?.(async (pendingPayment) => {
        console.log("pendingPayment ", pendingPayment);
        return {
          ...pendingPayment,
          job: (await getJobData(pendingPayment?.jobId)) ?? {},
        };
      })
    );

    // Map over the results to extract only the value of each object
    results = results.map((result) => result.value);

    return res.status(200).json({
      success: true,
      pendingPayments: results,
    });
  } catch (err) {
    console.error("Error fetching pending payments: ", err);
    res.status(500).json({ error: err.message });
  }
});
// Firebase Cloud Function to update a pending payment status to "completed"
exports.updatePaymentStatus = onRequest(async (req, res) => {
  try {
    // Extract paymentId from query parameters
    const paymentId = req.query.paymentId;

    // Validate the presence of the paymentId query parameter
    if (!paymentId) {
      return res.status(400).json({
        success: false,
        message: "Missing paymentId query parameter.",
      });
    }

    // Create a reference to the "pendingPayments" collection
    const pendingPaymentsCollection = fireStore.collection("pendingPayments");

    // Update the status of the payment with the paymentId to "completed"
    await pendingPaymentsCollection
      .doc(paymentId)
      .update({ status: "completed" });

    return res.status(200).json({
      success: true,
      message: 'Payment status updated to "completed".',
    });
  } catch (err) {
    console.error("Error updating payment status: ", err);
    res.status(500).json({ error: err.message });
  }
});

exports.createPaymentIntent = onRequest(async (req, res) => {
  logger.info("Hello logs!", { structuredData: true });
  const { name, amount, email, jobId, userId } = req.body;
  // Create a reference to the "paymentlogs" collection
  const jobsCollection = fireStore.collection("jobs");

  // Use the where() method to filter documents by the "jobId" field
  const jobDocRef = jobsCollection.doc(jobId);
  console.log(`it got here ${amount}`);
  const jobInfoScapShot = await jobDocRef.get();
  //console.log("jobInfoScapShot ", jobInfoScapShot)
  console.log("jobInfoScapShot.exists ", jobInfoScapShot.exists);
  const jobInfo = await jobInfoScapShot.data();
  console.log("jobInfo ", jobInfo);
  if (!jobInfo) {
    return res.status(400).json({
      success: false,
      message: "No jobs were found with the given id",
    });
  }
  if (jobInfo?.paidUsers?.includes(userId)) {
    return res.status(400).json({
      success: false,
      message: "You have already paid for this job.",
    });
  }
  let existingCustomers = await stripe.customers.list({ email: email });
  console.log("existingCustomers", existingCustomers);
  if (existingCustomers.data.length) {
    // don't create customer if already exists
    console.log("Don't create", existingCustomers.data[0].id);
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: existingCustomers.data[0].id },
      { apiVersion: "2023-08-16" }
    );
    // create intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency: "USD",
      customer: existingCustomers.data[0].id,
      description: "Customer Payment",
      metadata: {
        userId: userId,
        jobId: jobId,
      },
    });
    res.status(200).send({
      success: true,
      message: "Payment was completed successfully",
      paymentIntent: paymentIntent,
      ephemeralKey: ephemeralKey.secret,
      customer: existingCustomers.data[0].id,
      publishableKey: process.env.STRIPE_PUBISHABLE_KEY,
    });
  } else {
    console.log("create customer");
    //create customer first against email
    const customer = await stripe.customers.create({
      name: name,
      email: email,
    });
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customer.id },
      { apiVersion: "2023-08-16" }
    );
    console.log(customer);
    if (customer) {
      //charge customer after creating customer
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100),
        currency: "USD",
        customer: customer.id,
        description: "Customer Payment",
        metadata: {
          userId: userId,
          jobId: jobId,
        },
      });
      console.log(paymentIntent);
      if (paymentIntent) {
        res.status(200).send({
          success: true,
          message: "The payment was completed successfully",
          paymentIntent: paymentIntent,
          ephemeralKey: ephemeralKey.secret,
          customer: customer.id,
          publishableKey: process.env.STRIPE_PUBISHABLE_KEY,
        });
      }
    } else {
      res.status(422).send({
        success: false,
        message: "Error Creating New Customer",
      });
    }
  }
});

exports.stripewebhook = onRequest(async (req, res) => {
  //const { event } = req.body;
  //Get the Stripe signature from the headers
  const signature = req.headers["stripe-signature"];
  // Verify the webhook signature using your Stripe webhook signing secret
  console.log(
    "process.env.STRIPE_WEBHOOK_SECRET ",
    process.env.STRIPE_WEBHOOK_SECRET
  );
  const payloadData = req.rawBody;
  const payloadString = payloadData.toString();
  console.log("payloadString ", payloadString);
  //const event = stripe.webhooks.constructEvent(payloadString, req.headers['stripe-signature'], process.env.STRIPE_WEBHOOK_SECRET);
  //console.log("event ", event)
  const event = JSON.parse(payloadString);
  console.log("event ", event);
  switch (event.type) {
    case "payment_intent.succeeded":
      const paymentIntent = event.data.object;
      console.log("paymentIntent ", paymentIntent);
      const userId = paymentIntent?.metadata?.userId;
      const jobId = paymentIntent?.metadata?.jobId;
      console.log("userId ", userId);
      console.log("jobId ", jobId);
      const customString = await generateCustomString(20);
      console.log(customString);
      await fireStore.collection("paymentlogs").doc(customString).set({
        id: customString,
        userId: userId,
        jobId: jobId,
        paymentIntent: paymentIntent,
        createdAt: new Date(),
        isRefunded: false,
      });
      // Reference to the Firestore collection
      const jobsCollection = await fireStore.collection("jobs");
      const jobDocRef = jobsCollection.doc(jobId);
      let paidUsers;
      if (jobDocRef?.paidUsers) {
        paidUsers = jobDocRef?.paidUsers;
        paidUsers.push(userId);
      } else {
        paidUsers = [userId];
      }
      console.log("paidUsers ", paidUsers);
      const updatedData = {
        paidUsers: paidUsers,
      };
      jobDocRef
        .update(updatedData)
        .then(() => {
          console.log("Document successfully updated!");
        })
        .catch((error) => {
          console.error("Error updating document: ", error);
        });
      break;
    case "charge.refunded":
      const chargeObject = event.data.object;
      console.log("chargeObject ", chargeObject);
      if (chargeObject?.payment_intent) {
        console.log(
          "chargeObject?.payment_intent ",
          chargeObject?.payment_intent
        );
        // Create a reference to the "paymentlogs" collection
        const refundRequestsCollection = fireStore.collection("refundrequests");
        // Create a reference to the "jobs" collection
        const jobsCollection = fireStore.collection("jobs");
        // Create a reference to the "paymentlogs" collection
        const paymentLogsCollection = fireStore.collection("paymentlogs");

        // Use the where() method to filter documents by the "jobId" field
        const query = refundRequestsCollection.where(
          "paymentIntentId",
          "==",
          chargeObject?.payment_intent
        );

        // Execute the query and retrieve the documents
        const querySnapshot = await query.get();
        querySnapshot.forEach((doc) => {
          if (doc.exists) {
            // Access the data for each document
            const data = doc.data();
            console.log("Document data:", data);
            // Update the status field to "completed"
            const documentRef = refundRequestsCollection.doc(data.id);

            // Use the update method to update the document
            documentRef
              .update({ status: "completed" })
              .then(async () => {
                console.log("Document updated successfully.");
                console.log("jobId ", data.jobId);
                // Update the status field to "completed"
                const jobDocument = await jobsCollection.doc(data.jobId).get();
                if (!jobDocument.exists) {
                  console.log(`Could not find job with ID ${jobId}`);
                }

                const jobData = jobDocument.data();
                console.log("jobData", jobData);
                // Define the userId to remove from the arrays
                const userIdToRemove = data.userId;

                // Remove userId from the paidUsers array
                const updatedPaidUsers = jobData?.paidUsers.filter(
                  (userId) => userId !== userIdToRemove
                );

                // Remove userId from the refundRequestedUsers array
                const updatedRefundRequestedUsers =
                  jobData?.refundRequestedUsers.filter(
                    (userId) => userId !== userIdToRemove
                  );

                console.log("updatedPaidUsers", updatedPaidUsers);
                console.log(
                  "updatedRefundRequestedUsers",
                  updatedRefundRequestedUsers
                );
                const updatedData = await jobsCollection
                  .doc(data.jobId)
                  .update({
                    paidUsers: updatedPaidUsers,
                    refundRequestedUsers: updatedRefundRequestedUsers,
                  });
                const updatedPaymentLogData = await paymentLogsCollection
                  .doc(data.paymentLogId)
                  .update({
                    isRefunded: true,
                  });
                console.log("updation event succedded ", updatedData);
              })
              .catch((error) => {
                console.error("Error updating document:", error);
              });
          } else {
            console.log("Document does not exist");
          }
        });
      }
      break;
    case "customer.subscription.updated":
      const customerSubscriptionUpdated = event.data.object;
      console.log("customerSubscriptionUpdated ", customerSubscriptionUpdated);
      if (customerSubscriptionUpdated.cancel_at_period_end) {
        // Return a successful response to Stripe
        return res.sendStatus(200);
      }
      const customer3 = await stripe.customers.retrieve(
        customerSubscriptionUpdated?.customer
      );
      console.log("customer3 ", customer3);
      customerEmail = customer3?.email?.toLowerCase();
      ifUser = await User.findOne({ where: { email: customerEmail } });
      console.log("ifUser ", ifUser);
      const subscriptionId = customerSubscriptionUpdated?.id;
      const subscriptionStatus = customerSubscriptionUpdated?.status;
      console.log(
        "subscriptionId, subscriptionStatus ",
        subscriptionId,
        subscriptionStatus
      );
      priceId = customerSubscriptionUpdated?.plan?.id;
      ifPlan = await Plan.findOne({ where: { priceId } });
      if (
        customerSubscriptionUpdated.status == "incomplete_expired" ||
        customerSubscriptionUpdated.status == "incomplete" ||
        customerSubscriptionUpdated.status == "cancelled"
      ) {
      } else if (
        customerSubscriptionUpdated.status != "active" &&
        customerSubscriptionUpdated.status != "trialing"
      ) {
        const updatedUser = await User.update(
          {
            planId: ifPlan?.id,
            isPaid: true,
            subscriptionId: subscriptionId,
            subscriptionStatus: subscriptionStatus,
          },
          { where: { id: ifUser?.id } }
        );
        await updateContactsSubscriptionStatus(
          customerEmail,
          subscriptionStatus
        );
        console.log("updatedUser ", updatedUser);
      } else {
        console.log("its activing and trailing ");
        const updatedUser = await User.update(
          {
            planId: ifPlan?.id,
            isPaid: true,
            subscriptionId: subscriptionId,
            subscriptionStatus: subscriptionStatus,
          },
          { where: { id: ifUser?.id } }
        );
        await updateContactsSubscriptionStatus(
          customerEmail,
          subscriptionStatus
        );
        console.log("updatedUser ", updatedUser);
      }
      // Then define and call a function to handle the event subscription_schedule.canceled
      break;
    default:
      console.log("Unhandled event type:", event.type);
  }
  // Return a successful response to Stripe
  res.sendStatus(200);
});

exports.requestRefundPayment = onRequest(async (req, res) => {
  try {
    const idToken = await extractToken(req);
    let userId = null;
    await app
      .auth()
      .verifyIdToken(idToken)
      .then((decodedIdToken) => {
        console.log("decodedIdToken ", decodedIdToken);
        userId = decodedIdToken.uid;
      });
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Token expired",
      });
    }
    logger.info("Hello logs!", { structuredData: true });
    console.log("userId ", userId);
    const { jobId } = req.body;
    console.log("userId, jobId  ", userId, jobId);

    // Create a reference to the "paymentlogs" collection
    const jobsCollection = fireStore.collection("jobs");

    // Use the where() method to filter documents by the "jobId" field
    const jobDocRef = jobsCollection.doc(jobId);
    console.log("it got here ");
    const jobInfoScapShot = await jobDocRef.get();
    //console.log("jobInfoScapShot ", jobInfoScapShot)
    console.log("jobInfoScapShot.exists ", jobInfoScapShot.exists);
    const jobInfo = await jobInfoScapShot.data();
    console.log("jobInfo ", jobInfo);
    if (!jobInfo) {
      return res.status(400).json({
        success: false,
        message: "No job by this id",
      });
    }
    if (jobInfo?.refundRequestedUsers) {
      console.log(
        "jobInfo?.refundRequestedUsers, userId",
        jobInfo?.refundRequestedUsers,
        userId
      );
      if (jobInfo?.refundRequestedUsers.includes(userId)) {
        return res.status(400).json({
          success: false,
          message: "Refund request has already been initiated. ",
        });
      }
    }
    // Create a reference to the "paymentlogs" collection
    const paymentLogsCollection = fireStore.collection("paymentlogs");
    console.log("jobId, userId ", jobId, userId);
    // Use the where() method to filter documents by the "jobId" field
    const query = paymentLogsCollection
      .where("jobId", "==", jobId)
      .where("userId", "==", userId)
      .orderBy("isRefunded")
      .where("isRefunded", "!=", true)
      .orderBy("createdAt", "asc");
    // Execute the query and retrieve the documents
    const querySnapshot = await query.get();
    let paymentLog = null;
    try {
      querySnapshot.forEach((doc) => {
        if (doc.exists) {
          // Access the data for each document
          const data = doc.data();
          console.log("Document data:", data);
          paymentLog = data;
        } else {
          console.log("Document does not exist");
        }
      });
    } catch (error) {
      console.error("Error getting documents:", error);
    }
    console.log("paymentLog ", paymentLog);
    if (paymentLog) {
      const paymentIntentId = paymentLog?.paymentIntent?.id;
      console.log("paymentIntentId ", paymentIntentId);
      if (paymentIntentId) {
        const customString = await generateCustomString(20);
        console.log(customString);
        await fireStore.collection("refundrequests").doc(customString).set({
          id: customString,
          userId: userId,
          jobId: jobId,
          paymentIntentId: paymentIntentId,
          jobOwnerId: jobInfo?.ownerUid,
          status: "pending",
          paymentLogId: paymentLog.id,
        });
        // Update the job document and add a value to the "refundRequestedUsers" array
        let updatedRefundRequestedUsers;
        if (jobInfo?.refundRequestedUsers) {
          updatedRefundRequestedUsers = jobInfo?.refundRequestedUsers;
          updatedRefundRequestedUsers.push(userId);
        } else {
          updatedRefundRequestedUsers = [userId];
        }
        console.log(
          "updatedRefundRequestedUsers ",
          updatedRefundRequestedUsers
        );
        const updateData = {
          refundRequestedUsers: updatedRefundRequestedUsers,
        };

        try {
          await jobDocRef.update(updateData);
          // Your update was successful
        } catch (error) {
          console.error("Error updating job document:", error);
          // Handle the error as needed
        }
        return res.status(200).json({
          success: true,
          message: "Refund Request has been initiated",
        });
      } else {
        return res.status(400).json({
          success: false,
          message: "No Payment Log of this job",
        });
      }
    } else {
      return res.status(400).json({
        success: false,
        message: "Error: You have not paid for this job",
      });
    }
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
});

exports.confirmRefundRequest = onRequest(async (req, res) => {
  try {
    const idToken = await extractToken(req);
    let userId = null;
    await app
      .auth()
      .verifyIdToken(idToken)
      .then((decodedIdToken) => {
        console.log("decodedIdToken ", decodedIdToken?.uid);
        userId = decodedIdToken?.uid;
      });
    logger.info("Hello logs!", { structuredData: true });
    console.log("userId ", userId);
    logger.info("Hello logs!", { structuredData: true });
    const { requestId } = req.body;
    // Create a reference to the "paymentlogs" collection
    const refundRequestsCollection = fireStore.collection("refundrequests");

    // Use the where() method to filter documents by the "jobId" field
    const refundRequestDocRef = refundRequestsCollection.doc(requestId);
    console.log("it got here ");
    const refundRequestInfoScapShot = await refundRequestDocRef.get();
    //console.log("refundRequestInfoScapShot ", refundRequestInfoScapShot)
    console.log(
      "refundRequestInfoScapShot.exists ",
      refundRequestInfoScapShot.exists
    );
    const refundRequestInfo = await refundRequestInfoScapShot.data();
    console.log("refundRequestInfo ", refundRequestInfo);
    if (refundRequestInfo?.jobOwnerId != userId) {
      return res.status(400).json({
        success: true,
        message:
          "You can't confirm refund request as you are not the job owner.",
      });
    }
    if (refundRequestInfo) {
      const paymentIntentId = refundRequestInfo.paymentIntentId;
      console.log("paymentIntentId ", paymentIntentId);
      if (paymentIntentId) {
        const refund = await stripe.refunds.create({
          payment_intent: paymentIntentId,
          metadata: {
            refundRequestId: requestId,
          },
        });
        console.log("refund ", refund);
        await refundRequestDocRef.set({
          ...refundRequestInfo,
          status: "accepted", //pending, accepted, completed,
          refundId: refund.id,
        });
        return res.status(200).json({
          success: true,
          message: "Refund has been initiated",
          refundId: refund.id,
        });
      } else {
        return res.status(400).json({
          success: false,
          message: "No Payment Log of this job",
        });
      }
    }
  } catch (err) {
    console.log("err ", err);
    res.status(500).json({ error: err.message });
  }
});

exports.getRefundRequests = onRequest(async (req, res) => {
  try {
    //Get refund requests as seller
    const idToken = await extractToken(req);
    //let userId = "a59GWiWAeXOE2ftGIPPgC8ruRpl2"
    await app
      .auth()
      .verifyIdToken(idToken)
      .then((decodedIdToken) => {
        console.log("decodedIdToken ", decodedIdToken?.uid);
        userId = decodedIdToken?.uid;
      });
    console.log("userId ", userId);
    // Create a reference to the "refundrequests" collection
    const refundRequestsCollection = fireStore.collection("refundrequests");
    const jobCollection = fireStore.collection("jobs");
    const userCollection = fireStore.collection("users");
    // Use the where() method to filter documents by the "jobId" field
    const query = refundRequestsCollection.where("jobOwnerId", "==", userId);
    // let refundRequests = [];
    let querySnapshot = await query.get();
    if (querySnapshot?._size < 1) {
      return res.status(200).json({
        success: false,
        message: "You don't have any refund request right now",
      });
    }
    let refundRequests = [];
    console.log("querySnapshot", querySnapshot);
    querySnapshot?.forEach?.((result) => {
      refundRequests.push({
        ...result?.data?.(),
      });
    });

    let results = await Promise.allSettled(
      refundRequests?.map?.(async (refund) => {
        return {
          ...refund,
          job: (await getJobData(refund?.jobId)) ?? {},
          user: (await getUserData(refund?.userId)) ?? {},
        };
      })
    );

    refundRequests = [];
    let finalData = results?.forEach?.((result) => {
      if (result?.status === "fulfilled") {
        refundRequests.push({
          ...result?.value,
        });
      }
    });

    console.log("returning data ", refundRequests);

    return res.status(200).json({
      success: true,
      message: "Refund requests has been found",
      refundRequests,
    });
  } catch (err) {
    console.log("err ", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

exports.getBuyerRefundRequests = onRequest(async (req, res) => {
  try {
    //Get refund requests as seller
    const idToken = await extractToken(req);
    await app
      .auth()
      .verifyIdToken(idToken)
      .then((decodedIdToken) => {
        console.log("decodedIdToken ", decodedIdToken?.uid);
        userId = decodedIdToken?.uid;
      });
    console.log("userId ", userId);
    // Create a reference to the "refundrequests" collection
    const refundRequestsCollection = fireStore.collection("refundrequests");

    // Use the where() method to filter documents by the "jobId" field
    const query = refundRequestsCollection.where("userId", "==", userId);
    // let refundRequests = [];
    let querySnapshot = await query.get();
    if (querySnapshot?._size < 1) {
      return res.status(200).json({
        success: false,
        message: "You don't have any refund request right now",
      });
    }
    let refundRequests = [];
    console.log("querySnapshot", querySnapshot);
    querySnapshot?.forEach?.((result) => {
      refundRequests.push({
        ...result?.data?.(),
      });
    });

    let results = await Promise.allSettled(
      refundRequests?.map?.(async (refund) => {
        return {
          ...refund,
          job: (await getJobData(refund?.jobId)) ?? {},
          user: (await getUserData(refund?.userId)) ?? {},
        };
      })
    );

    refundRequests = [];
    let finalData = results?.forEach?.((result) => {
      if (result?.status === "fulfilled") {
        refundRequests.push({
          ...result?.value,
        });
      }
    });
    console.log("returning data ", refundRequests);
    return res.status(200).json({
      success: true,
      message: "Refund requests has been found",
      refundRequests,
    });
  } catch (err) {
    console.log("err ", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

exports.testFunction = onRequest(async (req, res) => {
  try {
    const { paymentIntentId, idToken } = req.body;
    // Confirm the Payment Intent using the Stripe SDK.
    const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId, {
      payment_method: "pm_card_visa",
      return_url: "https://www.google.com/success",
    });
    console.log("paymentIntent ", paymentIntent);
    // Check the status of the confirmed Payment Intent.
    if (paymentIntent.status === "succeeded") {
      // Payment was successful.
      res.json({
        status: "succeeded",
        message: "Payment confirmed successfully",
      });
    } else {
      // Payment did not succeed.
      res
        .status(400)
        .json({ status: "failed", message: "Payment confirmation failed" });
    }
  } catch (err) {
    console.log("err ", err);
  }
});

exports.createSetupIntent = onRequest(async (req, res) => {
  const { name, email, userId } = req.body;

  let existingCustomers = await stripe.customers.list({ email: email });
  var customer = existingCustomers.data[0];

  if (!existingCustomers.data.length) {
    console.log("Creating a new customer");
    customer = await stripe.customers.create({
      name: name,
      email: email,
    });
  }

  // create ephemeral key
  const ephemeralKey = await stripe.ephemeralKeys.create(
    { customer: customer.id },
    { apiVersion: "2023-08-16" }
  );

  // create intent
  const setupIntent = await stripe.setupIntents.create({
    payment_method_types: ["card"],
    customer: customer.id,
    metadata: {
      userId: userId,
    },
    usage: "off_session",
  });

  res.status(200).send({
    success: true,
    message: "Setup Intent was successfully created",
    setupIntent: setupIntent,
    ephemeralKey: ephemeralKey.secret,
    customer: existingCustomers.data[0].id,
    publishableKey: process.env.STRIPE_PUBISHABLE_KEY,
  });
});

exports.updateDefaultPaymentMethod = onRequest(async (req, res) => {
  const { stripePaymentId, stripeCustomerId } = req.body;
  const idToken = await extractToken(req);
  await app
    .auth()
    .verifyIdToken(idToken)
    .then((decodedIdToken) => {
      userId = decodedIdToken?.uid;
    });

  if (!userId) {
    return res.status(422).json({
      success: false,
      message: "The required `userId` parameter was not provided",
    });
  }
  if (!stripePaymentId || !stripeCustomerId) {
    await users.doc(userId).update({
      stripePaymentId: null,
      stripeCustomerId: null,
    });
    return res.status(200).json({
      success: false,
      message: "The payment method was removed for the given user",
    });
  }
  const users = fireStore.collection("users");
  await users.doc(userId).update({
    stripePaymentId: stripePaymentId,
    stripeCustomerId: stripeCustomerId,
  });

  return res.status(200).send({
    success: true,
    message: "Payment method was successfully saved for the user",
  });
});

exports.fetchDefaultPaymentMethod = onRequest(async (req, res) => {
  const idToken = await extractToken(req);
  await app
    .auth()
    .verifyIdToken(idToken)
    .then((decodedIdToken) => {
      userId = decodedIdToken?.uid;
    });

  if (!userId) {
    return res.status(422).json({
      success: false,
      message: "The required `userId` parameter was not provided",
    });
  }

  const usersDoc = fireStore.collection("users");
  const querySnapshot = await usersDoc.doc(userId).get();
  let data = querySnapshot?.data();
  if (data == null) {
    return res.status(404).json({
      message: "We were unable to find the given user: " + userId,
    });
  }
  console.log("We captured the data from the database");
  let paymentId = data.stripePaymentId;
  if (!paymentId) {
    return res.status(200).json({
      success: false,
      message:
        "We were unable to capture the given payment ID for the given user",
    });
  }
  console.log("Payment ID: " + paymentId);
  let stripeCustomerId = data.stripeCustomerId;
  if (!stripeCustomerId) {
    return res.status(200).json({
      success: false,
      message:
        "We were unable to find the given user with our payment provider",
    });
  }
  console.log("Stripe Customer ID: " + stripeCustomerId);
  let paymentMethod = await stripe.customers.retrievePaymentMethod(
    stripeCustomerId,
    paymentId
  );

  if (paymentMethod != null) {
    return res.status(200).json({
      success: true,
    });
  } else {
    console.log("No payment method found for the given user");
    return res.status(200).json({
      success: false,
      message: "No payment method found for the given user",
    });
  }
});

exports.customer = onRequest(async (req, res) => {
  let existingCustomers = await stripe.customers.list({ email: email });

  const { name, email } = req.body;
  if (existingCustomers.data.length) {
    ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: existingCustomers.data[0].id },
      { apiVersion: "2023-08-16" }
    );
  } else {
    //create customer first against email
    const customer = await stripe.customers.create({
      name: name,
      email: email,
    });
    ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customer.id },
      { apiVersion: "2023-08-16" }
    );
  }
  res.json({
    customer: customer.id,
    ephemeralKeySecret: ephemeralKey.secret,
  });
});

exports.defaultPayment = onRequest(async (req, res) => {
  const { email } = req.body;
  let existingCustomers = await stripe.customers.list({ email: email });
  if (existingCustomers.data.length) {
    customerId = existingCustomers.data[0].id;
  } else {
    //create customer first against email
    const customer = await stripe.customers.create({
      name: name,
      email: email,
    });

    customerId = customer.id;
  }

  const paymentMethods = await stripe.customers.listPaymentMethods(customerId, {
    limit: 1
  });

    if (
      paymentMethods["data"] != null &&
      paymentMethods["data"][0] != null &&
      paymentMethods["data"][0]["id"] != null &&
      paymentMethods["data"][0]["card"] != null &&
      paymentMethods["data"][0]["card"]["last4"]
    ) {
      res.json({
        id: paymentMethods["data"][0]["id"],
        last_4: paymentMethods["data"][0]["card"]["last4"],
      });
    } else {
      res.json({});
    }
});

exports.createConnectAccount = onRequest(async (req, res) => {
  try {
    const {name, email} = req.body;
    const account = await stripe.accounts.create({
      email: email,
      business_profile: {
        name: name
      },
      type: 'express',
      capabilities: {
        card_payments: {
          requested: true,
        },
        transfers: {
          requested: true,
        },
      },
      business_type: 'individual',
    });

    if(account) {
      return res.status(200).json({
        success: true,
        message: "Account connect created successfully",
        accountId: account['id'],
      });
    }
    return res.status(422).json({
      success: false,
      message: 'An error occur',
    });
  } catch (err) {
    console.log("err ", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});


exports.createAccountLink = onRequest(async (req, res) => {
  try {
    const {accountId, email, name} = req.body;
    var account = accountId;
    if(account == undefined || accountId == "") {
     
      const idToken = await extractToken(req);
      await app
        .auth()
        .verifyIdToken(idToken)
        .then((decodedIdToken) => {
          userId = decodedIdToken?.uid;
        });
    
      if (!userId) {
        return res.status(422).json({
          success: false,
          message: 'An error occur',
        });
      }

      var connectAccount = await stripe.accounts.create({
        email: email,
        type: 'express',
        business_type: 'individual',
        individual: {
          email: email || undefined,
          first_name: name || undefined,
        },
      });
      
      account = connectAccount.id;
      const usersDoc = fireStore.collection("users");
      await usersDoc.doc(userId).update({
        connectAccountId: account,
      });
      
    }
    const accountLink = await stripe.accountLinks.create({
      account: account,
      refresh_url: 'https://createaccountlink-7tciwcgjna-uc.a.run.app',
      return_url: 'https://example.com/return',
      type: 'account_onboarding',
    });

    if(accountLink) {
     return res.status(200).json({
        success: true,
        message: "Account link created successfully",
        linkUrl: accountLink.url,
      });
    }
    return res.status(422).json({
      success: false,
      message: 'An error occur',
    });
  } catch (err) {
    console.log("err ", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});


exports.createLoginLink = onRequest(async (req, res) => {
  try {
    const {accountId} = req.body;
    const loginLink = await stripe.accounts.createLoginLink(accountId);

    if(loginLink) {
     return res.status(200).json({
        success: true,
        message: "Login link created successfully",
        loginLinkUrl: loginLink.url,
      });
    }
    return res.status(422).json({
      success: false,
      message: 'An error occur',
    });
  } catch (err) {
    console.log("err ", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

exports.fetchConnectAccount = onRequest(async (req, res) => {
  try {
    const {accountId} = req.body;
    const account = await stripe.accounts.retrieve(accountId)

    if(account) {
     return res.status(200).json({
        success: true,
        message: "Account fetched successfully",
        accountId: account['id'],
        accountCompleted: account['details_submitted']
      });
    }
    return res.status(422).json({
      success: false,
      message: 'An error occur',
    });
  } catch (err) {
    console.log("err ", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

exports.getConnectAccountBalance = onRequest(async (req, res) => {
  try {
    const {accountId} = req.body;
    const balance = await stripe.balance.retrieve({
      stripeAccount: accountId,
    });

    if(balance) {
      const {amount, currency} = balance.available[0];
     return res.status(200).json({
        success: true,
        message: "Account balance fetched successfully",
        balance: amount,
        currency: currency
      });
    }
    return res.status(422).json({
      success: false,
      message: 'An error occur',
    });
  } catch (err) {
    console.log("err ", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

exports.requestPayout = onRequest(async (req, res) => {
  try {
    const {accountId, name} = req.body;
    const balance = await stripe.balance.retrieve({
      stripeAccount: accountId,
    });

    const {amount, currency} = balance.available[0];
    const payout = await stripe.payouts.create({
      amount: amount,
      currency: currency,
      statement_descriptor: `${name} Featrr payout`,
    }, {stripeAccount: accountId });
     return res.status(200).json({
        success: true,
        message: `${amount} paid to your account`,
      });
  } catch (err) {
    console.log("err ", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

exports.transferToConnectAccount = onRequest(async (req, res) => {
  try {
    const {email, amount, accountId} = req.body;
    // const charge = await stripe.charges.create({
    //   source: source,
    //   amount: amount,
    //   currency: 'USD',
    //   description: `Payment from Featrr ${email}`,
    //   statement_descriptor: `Payment from Featrr ${email}`,
    //   // The `transfer_group` parameter must be a unique id for the ride; it must also match between the charge and transfer
    //   transfer_group: 
    // });
    const transfer = await stripe.transfers.create({
      amount: Math.round(Number(amount) * 100) * 0.06,
      currency: 'USD',
      destination: accountId,
      description: `Payment from Featrr ${email}`,
    });

    if(transfer) {
     return res.status(200).json({
        success: true,
        message: "Transfer successfull",
        transferId: transfer['id'],
      });
    }
    return res.status(422).json({
      success: false,
      message: 'An error occur',
    });
  } catch (err) {
    console.log("err ", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});