<template>
  <div class="kafka-sender">
    <h2>Send Message to Kafka</h2>
    <div class="message-form">
      <textarea
        v-model="message"
        placeholder="Enter your message here..."
        rows="4"
        class="message-input"
      ></textarea>
      <button @click="sendMessage" :disabled="isLoading" class="send-button">
        {{ isLoading ? 'Sending...' : 'Send Message' }}
      </button>
    </div>
    <div v-if="response" :class="['response', response.success ? 'success' : 'error']">
      {{ response.message }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'KafkaMessageSender',
  data() {
    return {
      message: '',
      isLoading: false,
      response: null
    }
  },
  methods: {
    async sendMessage() {
      if (!this.message.trim()) {
        this.response = {
          success: false,
          message: 'Please enter a message'
        }
        return
      }

      this.isLoading = true
      this.response = null

      try {
        const response = await fetch(`${window.runtimeConfig.VUE_APP_API_URL}/send`, {
          method: 'POST',
          headers: {
            'Content-Type': 'text/plain'
          },
          body: this.message
        })

        if (response.ok) {
          this.response = {
            success: true,
            message: 'Message sent successfully!'
          }
          this.message = ''
        } else {
          throw new Error('Failed to send message')
        }
      } catch (error) {
        this.response = {
          success: false,
          message: `Error: ${error.message}`
        }
      } finally {
        this.isLoading = false
      }
    }
  }
}
</script>

<style scoped>
.kafka-sender {
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
}

.message-form {
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin: 20px 0;
}

.message-input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
  resize: vertical;
}

.send-button {
  padding: 10px 20px;
  background-color: #42b983;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.3s;
}

.send-button:hover {
  background-color: #3aa876;
}

.send-button:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}

.response {
  margin-top: 20px;
  padding: 10px;
  border-radius: 4px;
}

.success {
  background-color: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.error {
  background-color: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}
</style> 