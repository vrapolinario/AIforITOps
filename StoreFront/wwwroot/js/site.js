// Please see documentation at https://learn.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Chatbot Sidebar Logic
document.addEventListener('DOMContentLoaded', function () {
	var sidebar = document.getElementById('chatbotSidebar');
	var openBtn = document.getElementById('openChatbot');
	var closeBtn = document.getElementById('closeChatbot');
	var sendBtn = document.getElementById('sendChatbot');
	var input = document.getElementById('chatbotInput');
	var messages = document.getElementById('chatbotMessages');

	if (openBtn && sidebar) {
		openBtn.addEventListener('click', function () {
			sidebar.classList.add('open');
			openBtn.style.display = 'none';
		});
	}
	if (closeBtn && sidebar) {
		closeBtn.addEventListener('click', function () {
			sidebar.classList.remove('open');
			openBtn.style.display = 'block';
		});
	}
	function appendMessage(text, sender) {
		var msgDiv = document.createElement('div');
		msgDiv.className = sender === 'user' ? 'chatbot-msg-user' : 'chatbot-msg-bot';
		msgDiv.textContent = text;
		messages.appendChild(msgDiv);
		messages.scrollTop = messages.scrollHeight;
	}
	if (sendBtn && input) {
		sendBtn.addEventListener('click', function () {
			var text = input.value.trim();
			if (text) {
				appendMessage(text, 'user');
				input.value = '';
				appendMessage('Bot is thinking...', 'bot');
				fetch('/api/chatbot', {
					method: 'POST',
					headers: {
						'Content-Type': 'application/json'
					},
					body: JSON.stringify({ question: text })
				})
				.then(response => response.json())
				.then(data => {
					// Remove 'Bot is thinking...' message
					var botMsgs = messages.getElementsByClassName('chatbot-msg-bot');
					if (botMsgs.length > 0) {
						botMsgs[botMsgs.length - 1].remove();
					}
					appendMessage(data.answer, 'bot');
				})
				.catch(() => {
					appendMessage('Sorry, there was an error contacting the bot.', 'bot');
				});
			}
		});
		input.addEventListener('keydown', function (e) {
			if (e.key === 'Enter') {
				sendBtn.click();
			}
		});
	}
});
