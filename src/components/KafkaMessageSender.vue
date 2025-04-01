<template>
  <div class="kafka-sender">
    <div class="container">
      <h1>Kafka Message Sender</h1>

      <div class="message-form">
        <textarea
          v-model="message"
          placeholder="Enter your message here..."
          rows="4"
          class="message-input"
        ></textarea>
        
        <button 
          @click="sendMessage" 
          :disabled="isLoading"
          class="send-button"
        >
          {{ isLoading ? 'Sending...' : 'Send Message' }}
        </button>
      </div>

      <div v-if="response" class="response">
        {{ response }}
      </div>
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
      response: null,
      apiUrl: 'http://kafka-producer-service-kafka.apps.okd4.elc.com'
    }
  },
  methods: {
    async sendMessage() {
      if (!this.message.trim()) return

      this.isLoading = true
      this.response = null

      try {
        const response = await fetch(`${this.apiUrl}/send`, {
          method: 'POST',
          headers: {
            'Content-Type': 'text/plain',
            'Accept': 'text/plain',
            'Origin': window.location.origin
          },
          mode: 'cors',
          credentials: 'omit',
          body: this.message
        })

        const responseText = await response.text()
        
        if (response.ok) {
          this.response = responseText
          this.message = ''
        } else {
          throw new Error(`Server responded with status: ${response.status}`)
        }
      } catch (error) {
        console.error('Send message failed:', error)
        this.response = `Error: ${error.message}`
      } finally {
        this.isLoading = false
      }
    }
  }
}
</script>

<style scoped>
.kafka-sender {
  padding: 2rem;
}

.container {
  max-width: 600px;
  margin: 0 auto;
}

.message-form {
  margin-top: 2rem;
}

.message-input {
  width: 100%;
  padding: 1rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  margin-bottom: 1rem;
  resize: vertical;
}

.send-button {
  width: 100%;
  padding: 0.8rem;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.send-button:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}

.response {
  margin-top: 1rem;
  padding: 1rem;
  background-color: #f5f5f5;
  border-radius: 4px;
}
</style> 