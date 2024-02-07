import axios from "axios";
import env from "./env";

const instance = axios.create({
  baseURL: env.apiUrl,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
});

export default instance;
